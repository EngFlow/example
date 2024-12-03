#include <iostream>
#include "hello.h"

int main() {
  auto got = hello();
  if (got != "hello") {
    std::cerr << "got '" << got << "', want 'hello'" << std::endl;
    return 1;
  }
  return 0;
}
