import Testing

@Suite
struct HelloTest {
    @Test
    func example() {
        print("Hello from HelloTest")
        #expect(1 + 1 == 2)
    }
}
