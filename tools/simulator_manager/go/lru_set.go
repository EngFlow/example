package main

// LRUSet is a Set that has a maximum capacity and evicts the least recently used item when full.
type LRUSet[T comparable] struct {
	capacity int
	// An array to keep track of the order in which elements were inserted.
	// The first element in the array is the least recently used.
	order []T
	// A map to enable fast O(1) membership tests.
	storage map[T]struct{}
}

func NewLRUSet[T comparable](capacity int) *LRUSet[T] {
	if capacity <= 0 {
		panic("Capacity must be greater than zero.")
	}
	return &LRUSet[T]{
		capacity: capacity,
		order:    make([]T, 0, capacity),
		storage:  make(map[T]struct{}),
	}
}

// Insert returns an element that was evicted from the set.
func (s *LRUSet[T]) Insert(element T) *T {
	var evicted *T
	if _, exists := s.storage[element]; exists {
		// Remove from current position in order
		for i, e := range s.order {
			if e == element {
				old := s.order[i]
				evicted = &old
				s.order = append(s.order[:i], s.order[i+1:]...)
				break
			}
		}
		s.order = append(s.order, element)
	} else {
		if len(s.order) >= s.capacity && len(s.order) > 0 {
			oldest := s.order[0]
			s.order = s.order[1:]
			delete(s.storage, oldest)
			evicted = &oldest
		}
		s.order = append(s.order, element)
		s.storage[element] = struct{}{}
	}
	return evicted
}

func (s *LRUSet[T]) Contains(element T) bool {
	_, exists := s.storage[element]
	return exists
}

func (s *LRUSet[T]) Elements() []T {
	return s.order
}
