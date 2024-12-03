package greeting

import "testing"

func TestHello(t *testing.T) {
	if Greeting() != "Hello, world!" {
		t.Errorf("Greeting() = %v, want \"Hello, world!\"", Greeting())
	}
}
