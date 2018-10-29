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
    value_t a = nil();
    value_t b = false_();
    value_t c = true_();
    value_t d = number(42);
    value_t e = number(0.25);
    value_t f = string("foobarbaz", 9);
    value_t g = string("foobarbaz", 9);

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
    value_t a = table();
    value_t b = table();
    assert(a == a);
    assert(a != b);
  }

  {
    value_t a = function(3, true, [&](array_ptr A, array_ptr V) -> array_ptr {
      std::cout
          << (*A)[0] << " "
          << (*A)[1] << " "
          << (*A)[2] << " "
          << (*V)[0] << " "
          << (*V)[1] << " "
          << (*V)[2] << "\n";
      // return { number(1), number(2) };
      return newarray({ number(42) }, A);
    });
    auto r = a.call1({
      number(17),
      number(23),
      number(37),
      string("foo"),
      string("bar"),
      string("baz"),
    }, nullptr);
    std::cout << r << "\n";
    assert(r.is_number());
    assert(r == number(42));
    assert(r != string("42"));
  }

  {
    value_t t = table();
    t.settable(number(1), string("foo"));
    t.settable(number(2), string("bar"));
    t.settable(number(3), string("baz"));
    std::cout
        << t.gettable(number(1)) << " "
        << t.gettable(number(2)) << " "
        << t.gettable(number(3)) << "\n";
    t.settable(number(3), nil());
    std::cout
        << t.gettable(number(1)) << " "
        << t.gettable(number(2)) << " "
        << t.gettable(number(3)) << "\n";
  }

  {
    value_t env = open_env();
    env.gettable(string("print")).call({ number(42), string("foo") });
  }

  return 0;
}
