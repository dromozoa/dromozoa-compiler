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



/*
  type_t t = type_t::number;
  std::cout << static_cast<int>(t) << "\n";

  value_t v = value_t::string("foobarbaz", 9);
  std::cout << sizeof(v) << "\n";
  std::cout << v << "\n";

  value_t b(value_t::boolean(true));
  std::cout << b << "\n";

  value_t t1(value_t::table());
  std::cout << t1 << "\n";
  value_t t2 = t1;
  std::cout << t2 << "\n";

  value_t f = value_t::function(3, false, [=](array_ptr args, array_ptr) -> tuple_t {
    std::cout << "!!!\n";
    return { { value_t::number(1.5) }, args };
  });
  std::cout << f << "\n";

  array_ptr a = std::make_shared<array_t>();
  a->push_back(TRUE);
  a->push_back(NIL);
  a->push_back(FALSE);
  tuple_t r1({ value_t::number(42) }, a);
  tuple_t r2({ value_t::number(42) });
  tuple_t r3({}, a);
  std::cout << r1.size() << "\n";
  std::cout << r2.size() << "\n";
  std::cout << r3.size() << "\n";

  std::cout << r1[0] << "\n";
  std::cout << r1[1] << "\n";
  std::cout << r1[2] << "\n";
  std::cout << r1[3] << "\n";
  std::cout << r1[4] << "\n";

  function_t g(3, true, [=](array_ptr A, array_ptr V) -> tuple_t {
    for (const value_t& a : *A) {
      std::cout << "A " << a << "\n";
    }
    for (const value_t& v : *V) {
      std::cout << "V " << v << "\n";
    }
    return { { TRUE }, V };
  });

  tuple_t result = g.call({ value_t::number(1), value_t::number(2), value_t::number(3), value_t::number(4), value_t::number(5) });
*/

  return 0;
}
