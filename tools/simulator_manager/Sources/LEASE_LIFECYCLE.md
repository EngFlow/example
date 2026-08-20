# The lifecycle of a simulator lease

This is a reasoning walkthrough of everything that happens to one lease, from
`POST /simulator/<pid>` to the device eventually being deleted (or handed to
someone else). It's meant to make the state machine in `SimulatorManager.swift`
easy to hold in your head, not to restate the architecture already covered in
`README.md`.

## The actors

- **A slot** (`SimulatorSlot`) is one device-shaped bucket for a `SimulatorConfig`.
  It's `empty`, `pendingCreation`, `active`, `pendingDeletion`, or `deleting`.
- **A lease** (`SimulatorLease` in memory, `PersistedLease` on disk) is the
  daemon's record that PID `p` is holding device `udid` in slot `i`.
- **A reference count** (`referenceCount[udid]`) is how many leases currently
  point at that device. Non-exclusive leases for the same config can share one
  device, so this can be > 1; exclusive leases never share, so it's always
  exactly 1 while active.

A lease and a slot are related but not the same thing: the slot is about the
*device*, the lease is about *who's holding it*. A non-exclusive device can
outlive any single lease on it (reused by the next leaser), and a lease always
maps to exactly one slot at a time.

## Phase 1 — request arrives

`SimulatorRequestHandler` parses the HTTP request and calls
`SimulatorManager.lease(to:exclusive:config:)`. First check, before anything
else: does this PID already have a lease? (`leases[leaser]` in
`SimulatorManager.swift:305`). One process, one simulator — this isn't a
counter, it's a hard rule enforced synchronously (no `await` before the
check), so two concurrent requests from the same PID can't both slip through.

## Phase 2 — is the leaser even still there?

Before doing anything expensive, the manager checks `processIsRunning(leaser)`
(only when `deleteOnPIDExit` is set — otherwise the caller owns the PID's
lifetime and it need not be a real process at all, e.g. in tests). This looks
redundant — surely the caller wouldn't ask for a lease if it's already dead —
but the point isn't "is it dead right now," it's "is it dead *before we commit
to a multi-minute operation*." Provisioning is the expensive part; checking
liveness is nearly free. This is the cheap half of a two-part guard; the
expensive half is Phase 4.

## Phase 3 — finding a device: the slot state machine

This is the core of `getSimulator()`. Slots for the requested config are
sorted by `SimulatorSlot.sortOrder` and walked in order, taking the first one
that matches. The order (after the fix earlier in this session) is:

1. **`active`, non-exclusive, and the request is non-exclusive** — reuse it
   directly. This is the fast path: no provisioning at all, just
   `ensureBooted` as a sanity check.
2. **`pendingDeletion`** — a device that's fully created and booted, just
   waiting out its idle timer. Reusing it is just as cheap as case 1; the
   *only* reason it wasn't in case 1 is that its reference count already hit
   zero once. Grabbing it cancels the scheduled deletion task and reassigns
   its exclusivity to whatever the new lease wants — which is fine, since
   "pending deletion" means nobody currently holds it, so there's no
   conflicting owner to worry about.
3. **`empty`** — nobody's even started building a device for this slot index.
   Start a fresh clone.
4. **`pendingCreation`, non-exclusive, and the request is non-exclusive** —
   someone else is already cloning a device for this config; wait on their
   task and count as a second (or third...) leaser of it once it's ready.

The interesting design choice is putting `empty` *ahead of* `pendingCreation`.
It means a new non-exclusive request would rather kick off a second,
independent clone than wait behind someone else's in-flight one, even though
the in-flight one might finish sooner. My read: this trades a bit of
redundant provisioning work for not making a request's latency depend on
someone else's request. It also means the pool tends to grow to "however many
concurrent first-requests there were for a config" before it starts
consolidating onto reuse — which matches the doc's framing of `pendingCreation`
sharing as a bonus for latecomers, not the primary mechanism.

Exclusive requests only ever match case 3 (fresh empty slot) or fall through
to appending a brand new slot — they never share `active`, `pendingCreation`,
or (implicitly, since case 2 always wins first if reached) another lease's
slot. `pendingDeletion` is the one case exclusive requests *do* match, and
that's safe precisely because "pending deletion" implies zero current owners.

If nothing matches, a new slot is appended at the end of the array — the pool
for a config only grows on demand, never pre-allocated.

## Phase 4 — provisioning, and when the reference count actually increments

This part is subtle because of the actor-isolation rule spelled out in a
comment above `getSimulator`: slot state must be updated *before* the first
`await`, or a concurrent call could observe a stale slot. That rule shapes
where reference counting happens too — it can't just happen "whenever," it has
to happen at the exact point where the device becomes claimed, before any
suspension point could let the device get swept into deletion by someone else
finishing first. Three different code paths each own this responsibility:

- **Reuse (`reuseSimulator`)**: increments immediately, *then* awaits
  `ensureBooted`. If boot fails with "invalid device" (exit 148), it deletes
  the corpse and clones a replacement — the increment from the original
  attempt is moot because `delete()` wipes the reference count entry outright,
  and the replacement gets its own fresh increment via `createCloneTask`.
- **Fresh clone (`createCloneTask`)**: increments right after the clone
  finishes, before returning, on the theory (per the comment in the code)
  that whoever created the device should be the one to count it, and anyone
  who later shares that same task must increment separately.
- **Joining an in-flight `pendingCreation`**: increments after awaiting the
  shared task's result — this is the "anyone who shares it counts separately"
  half of the previous point.

So for a config with 3 non-exclusive leases sharing one device, there are 3
separate `incrementReferenceCount` calls across possibly all three code paths,
never a batch increment. That's what makes "decrement to zero → pendingDeletion"
in Phase 6 a safe signal: it really does mean the last leaser let go.

Once a device is in hand, the lease is recorded in `leases[leaser]` and
persisted to disk (`persistLeases()`) *before* the second liveness check. Then
liveness is checked again — the expensive half of the Phase 2 guard. Cloning
and booting can take a real amount of wall-clock time (comment says
"minutes"), long enough for a test harness's timeout to have killed the leaser
already. If that happened, the manager doesn't hand back a UDID nobody will
ever release — it calls `release(for: leaser)` on itself immediately and
reports `leaserExited`. Recording the lease first (even though it's about to
be released) is what lets `release()` work at all; it operates purely on
`leases[leaser]`, it has no other way to find the device.

Only after surviving both liveness checks does the manager register a process-
exit watcher (`registerReleaseOnExit`) — no point watching a PID you're not
going to hand anything to.

## Phase 5 — active

The device sits in `leases[leaser]` and as `.active(udid, exclusive)` in its
slot, reference-counted. Nothing happens to it on its own; it just waits for
one of the release triggers below. Multiple non-exclusive leases can be
pointing at the same UDID simultaneously, each with their own entry in
`leases`, all decrementing the same shared `referenceCount[udid]` independently
whenever *they* release.

## Phase 6 — release: three ways in

1. **Explicit `DELETE /simulator/<pid>`** → `SimulatorRequestHandler` →
   `SimulatorManager.release(for:)`.
2. **The leasing process exits** without ever calling DELETE — caught by the
   `DispatchSourceProcess` registered in Phase 4, which calls `release(for:)`
   itself. This is what makes leases safe against a build tool that
   `kill -9`s a test that forgot to clean up.
3. **The daemon is replaced and the leaser didn't survive the handover** —
   handled entirely in `restoreLeases()` at startup, not in `release()` at all;
   see Phase 8. The lease is just never adopted, so no explicit release call
   ever happens for it, and the device is later picked up implicitly by name.

`release()` itself is small and ordered deliberately:

1. Pop the lease out of `leases` (also the point where a nonexistent lease
   surfaces as `SimulatorManagerError.noLease` — expected after a daemon
   restart dropped a lease the caller doesn't know is gone).
2. Persist the *now-shorter* lease list — before touching the device, so a
   daemon replaced mid-release doesn't try to re-adopt a lease whose device is
   about to be torn down.
3. Cancel the exit watcher (no longer relevant).
4. Clean temp files on the device.
5. Decrement the reference count, which is where the real branch happens.

## Phase 7 — idle, and the reference count reaching zero

`decrementReferenceCount` only does something interesting when the count hits
zero: it hands off to `pendingDeletion()`. If both idle timers are configured
as zero, deletion is immediate — no grace period at all. Otherwise a task is
scheduled that polls once a second, and *at every tick* re-decides which
deadline applies by checking `recentlyLeased.contains(config)` fresh. That's a
live check, not a snapshot taken when the task started — a config that gets
leased again elsewhere while this device is winding down flips it from the
short deadline to the long one (or the reverse, if it falls out of the
LRU set's capacity) mid-wait. It's a genuinely dynamic decision, not "pick a
deadline once."

Two ways out of `pendingDeletion`:

- **Resurrection**: a new lease for the same config finds this slot before the
  timer expires (Phase 3, case 2) and turns it back into `active`. The
  scheduled task gets cancelled, and because `Task.sleep` throws on
  cancellation, the task body simply unwinds without ever calling `delete()`.
- **Timeout**: the deadline is reached, the task double-checks the slot still
  holds *this exact device* (guarding against a resurrection racing the
  cancellation), and calls `delete()` for real — `simctl delete`, slot to
  `.deleting` then `.empty`, and (if `cleanUpSlots: true`) trims trailing empty
  slots off the end of the array so the pool doesn't grow unboundedly with
  dead slot indices.

## Phase 8 — surviving a daemon restart

This is the one part of the lifecycle that doesn't originate from an HTTP
request at all — it happens once, at startup, before the server even binds.
`start.sh` replaces the daemon on every new version, which would otherwise
silently orphan every in-flight lease. The fix is that every lease mutation in
Phases 4, 6, and 7 already persists the *entire* current lease set to disk
(atomically), so `restoreLeases()` just has to read that file back and decide,
per lease, whether to trust it:

1. **Did the leasing process survive?** Not just "is this PID alive" — PIDs
   recycle, so it also compares the process's actual start time
   (`kinfo_proc`) against what was recorded at lease time. A live PID with a
   *different* start time means a different process entirely; treated as
   exited.
2. **Does adopting it contradict something already restored?** Two leases
   can't share one exclusive device, and one slot can't hold two devices. A
   file that claims otherwise is treated as corrupt rather than trusted.

A lease that passes both checks gets its slot rebuilt as `.active`, its
reference count bumped, and (if configured) a fresh exit watcher — from that
point on it's indistinguishable from a lease that was granted moments ago by
this same daemon. A lease that fails either check is simply dropped — not
released, not cleaned up, just forgotten. Its device isn't touched at all.
`createBase`/`clone` look up devices by name before creating new ones, so an
orphaned device gets rediscovered and correctly reference-counted the next
time something happens to lease that same config — but if nothing ever leases
that exact config again, this lazy reconciliation never fires. See Phase 9
for the backstop that catches that case.

## Phase 9 — the orphan reaper

Every cleanup path above is triggered by an event: a release call, a PID
exit, an idle timer, or "the same config got leased again." Each of those can
miss a device — Phase 8 above is one way (a lease that never gets re-leased),
and a `simctl delete` call inside `delete()` failing silently (it's called as
`try? await delete(...)`, and the slot is reset to `.empty` in a `defer`
regardless of whether the delete actually succeeded) is another. Either way,
nothing else ever looks for that device again.

`startReaper(interval:)` runs a sweep on a timer, independent of any lease
event, that reconciles against reality instead of the event stream: it lists
every simulator named with the manager's clone prefix
(`SimulatorConfig.cloneDeviceName`, so base simulators and anything not
created by this manager are never touched) and deletes any whose UDID has no
entry in `referenceCount` — the same dictionary key presence check works here
as everywhere else, since an entry exists from the moment a device is claimed
until `delete()` removes it, including through the idle-timer grace period.

To avoid deleting a clone that's mid-creation (it exists on disk for a moment
before `createCloneTask` resumes and records it in `referenceCount`), a
device must show up as unknown on two consecutive sweeps before it's reaped.
Deletion goes straight through `simulatorControl`, not through `delete()`:
an orphan has no slot pointing at it, so there's nothing in `simulatorSlots`
for `delete()`'s bookkeeping to update.

## Where this got subtle

- The "mutate slot before the first `await`" rule is easy to state and easy to
  violate by accident; it's the reason reference-count bookkeeping is smeared
  across three different functions instead of living in one place.
- `pendingDeletion` slots deliberately don't remember their old exclusivity
  flag — and don't need to, because reaching that state already implies zero
  current owners.
- The dynamic (not snapshotted) recheck of `recentlyLeased` inside the idle-
  deletion poll loop means the *duration* of a device's grace period can
  change while it's already ticking.
- Persistence is a side effect of every state change, not a periodic snapshot
  or a shutdown hook — which is what makes it safe against `kill -9`.
