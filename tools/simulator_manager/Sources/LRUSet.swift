/// A `Set` that has a maximum capacity and evicts the least recently used item
// when full.
struct LRUSet<Element: Hashable> {
  private let capacity: Int
  // An array to keep track of the order in which elements were inserted.
  // The first element in the array is the least recently used.
  private var order: [Element] = []

  // A Set to enable fast O(1) membership tests.
  private var storage: Set<Element> = []

  init(capacity: Int) {
    precondition(capacity > 0, "Capacity must be greater than zero.")
    self.capacity = capacity
  }

  // Returns an element that was evicted from the set, or nil if nothing was evicted
  // (including when `element` was already present and just moved to most-recently-used).
  mutating func insert(_ element: Element) -> Element? {
    if storage.contains(element) {
      if let index = order.firstIndex(of: element) {
        order.remove(at: index)
      }

      order.append(element)
      return nil
    }

    let evicted: Element?
    if order.count >= capacity, let oldest = order.first {
      order.removeFirst()
      evicted = storage.remove(oldest)
    } else {
      evicted = nil
    }

    order.append(element)
    storage.insert(element)
    return evicted
  }

  func contains(_ element: Element) -> Bool {
    return storage.contains(element)
  }

  var elements: [Element] {
    return order
  }
}
