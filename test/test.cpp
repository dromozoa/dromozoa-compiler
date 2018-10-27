#include "runtime/runtime_cxx.hpp"

#include <cassert>
#include <sstream>

inline std::string to_string(const dromozoa::runtime::value_t& v) {
  std::ostringstream out;
  out << v;
  return out.str();
}

int main(int, char*[]) {
  using namespace dromozoa::runtime;

  {
    value_t a = NIL;
    value_t b = FALSE;
    value_t c = TRUE;
    value_t d = value_t::number(42);
    value_t e = value_t::number(0.25);
    value_t f = value_t::string("foobarbaz", 9);
    value_t g = value_t::string("foobarbaz", 9);

    std::cout
        << a << " "
        << b << " "
        << c << " "
        << d << " "
        << e << " "
        << f << " "
        << g << "\n";

    assert(a == a);
    assert(b != c);
    assert(f == f);
    assert(f == g);
  }

  {
    value_t a = value_t::table();
    value_t b = value_t::table();
    assert(a == a);
    assert(a != b);
  }

  return 0;
}
