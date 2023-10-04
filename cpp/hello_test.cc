#include <iostream>
#include "cpp/hello.h"

int main() {
  auto got = hello();
  if (got != "hello") {
    std::cerr << "got '" << got << "', want 'hello'" << std::endl;
    return 1;
  }
  return 0;
}
