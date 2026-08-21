package main

import (
	"os"
)

// PTY represents a pseudo-terminal pair (replaced with pipe for simplicity).
// For child process stdout/stderr capture, pipes work just as well as PTYs
// and don't require CGO.
type PTY struct {
	Parent int
	Child  int
}

func NewPTY() (*PTY, error) {
	r, w, err := os.Pipe()
	if err != nil {
		return nil, err
	}
	return &PTY{
		Parent: int(r.Fd()),
		Child:  int(w.Fd()),
	}, nil
}
