package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestLRUSet_InsertAndContains(t *testing.T) {
	s := NewLRUSet[string](2)

	assert.Nil(t, s.Insert("a"))
	assert.True(t, s.Contains("a"))
	assert.False(t, s.Contains("b"))
}

func TestLRUSet_EvictsLeastRecentlyUsed(t *testing.T) {
	s := NewLRUSet[string](2)

	s.Insert("a")
	s.Insert("b")

	evicted := s.Insert("c")
	assert.NotNil(t, evicted)
	assert.Equal(t, "a", *evicted)
	assert.False(t, s.Contains("a"))
	assert.True(t, s.Contains("b"))
	assert.True(t, s.Contains("c"))
}

func TestLRUSet_ReinsertingExistingElementRefreshesItsPosition(t *testing.T) {
	s := NewLRUSet[string](2)

	s.Insert("a")
	s.Insert("b")

	// Touching "a" again should make "b" the least-recently-used one instead.
	evicted := s.Insert("a")
	assert.Nil(t, evicted, "re-inserting an existing element should not evict anything")

	evicted = s.Insert("c")
	assert.NotNil(t, evicted)
	assert.Equal(t, "b", *evicted, "\"b\" should have become least-recently-used after \"a\" was touched")
	assert.True(t, s.Contains("a"))
	assert.True(t, s.Contains("c"))
}

func TestLRUSet_Elements_ReflectsInsertionOrder(t *testing.T) {
	s := NewLRUSet[string](3)
	s.Insert("a")
	s.Insert("b")
	s.Insert("c")

	assert.Equal(t, []string{"a", "b", "c"}, s.Elements())
}

func TestLRUSet_CapacityMustBePositive(t *testing.T) {
	assert.Panics(t, func() { NewLRUSet[string](0) })
	assert.Panics(t, func() { NewLRUSet[string](-1) })
}
