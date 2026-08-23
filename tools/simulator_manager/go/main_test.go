package main

// main() itself isn't covered here: it parses process-global flags and calls
// os.Exit on invalid input, neither of which can be exercised safely from
// within the test binary's own process.

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestArrayFlags_SetAppendsInOrder(t *testing.T) {
	var flags arrayFlags

	assert.NoError(t, flags.Set("a"))
	assert.NoError(t, flags.Set("b"))

	assert.Equal(t, arrayFlags{"a", "b"}, flags)
	assert.Equal(t, "a, b", flags.String())
}

func TestArrayFlags_StringOnEmpty(t *testing.T) {
	var flags arrayFlags
	assert.Equal(t, "", flags.String())
}
