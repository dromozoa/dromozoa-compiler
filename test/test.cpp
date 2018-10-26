#include "runtime/runtime_cxx.hpp"

#include <iostream>

int main(int, char*[]) {
  using namespace dromozoa::runtime;

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

  value_t f = value_t::function(3, false, [=](array_ptr args, array_ptr) -> result_t {
    std::cout << "!!!\n";
    return { { value_t::number(1.5) }, args };
  });
  std::cout << f << "\n";

  array_ptr a = std::make_shared<array_t>();
  a->push_back(value_t::boolean(true));
  a->push_back(value_t::boolean(false));
  a->push_back(value_t());
  result_t r{ { value_t::number(42) }, a };
  // result_t r{ value_t::number(42) };
  // result_t r{ a };
  std::cout << r.size() << "\n";




  return 0;
}
