// Copyright (C) 2018 Tomoyuki Fujimori <moyu@dromozoa.com>
//
// This file is part of dromozoa-compiler.
//
// dromozoa-compiler is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// dromozoa-compiler is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// Under Section 7 of GPL version 3, you are granted additional
// permissions described in the GCC Runtime Library Exception, version
// 3.1, as published by the Free Software Foundation.
//
// You should have received a copy of the GNU General Public License
// and a copy of the GCC Runtime Library Exception along with
// dromozoa-compiler.  If not, see <http://www.gnu.org/licenses/>.

#include "runtime_cxx_value.hpp"

#include <functional>
#include <tuple>
#include <iostream>

namespace dromozoa {
  namespace runtime {
    inline void test(int x, int y, int z, int w) {
      std::cout
          << x << " "
          << y << " "
          << z << " "
          << w << "\n";
    }

    inline void test_f(value_t x, value_t y, value_t z) {
      std::cout
          << x.tostring() << " "
          << y.tostring() << " "
          << z.tostring() << "\n";
    }

    template <class T>
    void dump() {
      std::cout << __PRETTY_FUNCTION__ << "\n";
    }

    template <class T>
    void dump(T) {
      std::cout << __PRETTY_FUNCTION__ << "\n";
    }

    template <class T>
    void callable(T) {
      dump<arguments_type_t<T>>();
    }

    struct const_callable_t {
      int operator()(int, double) const { return 0; }
    };

    struct mutable_callable_t {
      int operator()(int, double) { return 0; }
    };

    struct not_callable_t {};
  }
}

int main(int, char*[]) {
  using namespace dromozoa::runtime;
  std::cout << sizeof(value_t) << "\n";

  std::string s = "bar";

  value_t r;
  r = 42 < 69;
  std::cout << r.tostring() << "\n";
  r = 42;
  std::cout << r.tostring() << "\n";
  r = "foo";
  std::cout << r.tostring() << "\n";
  r = s;
  std::cout << r.tostring() << "\n";
  r = std::string("baz");
  std::cout << r.tostring() << "\n";
  r = {};
  std::cout << r.tostring() << "\n";
  r = type_t::table;
  std::cout << r.tostring() << "\n";

  {
    array_t x;
    std::cout << "#=" << x.size << "\n";
    for (std::size_t i = 0; i < x.size; ++i) {
      std::cout << "[" << i << "]=" << x[i].tostring() << "\n";
    }
  }

  {
    array_t x{};
    std::cout << "#=" << x.size << "\n";
    for (std::size_t i = 0; i < x.size; ++i) {
      std::cout << "[" << i << "]=" << x[i].tostring() << "\n";
    }
  }

  {
    array_t x(1);
    std::cout << "#=" << x.size << "\n";
    for (std::size_t i = 0; i < x.size; ++i) {
      std::cout << "[" << i << "]=" << x[i].tostring() << "\n";
    }
  }

  {
    array_t x{1};
    std::cout << "#=" << x.size << "\n";
    for (std::size_t i = 0; i < x.size; ++i) {
      std::cout << "[" << i << "]=" << x[i].tostring() << "\n";
    }
  }

  {
    array_t x{1,2};
    std::cout << "#=" << x.size << "\n";
    for (std::size_t i = 0; i < x.size; ++i) {
      std::cout << "[" << i << "]=" << x[i].tostring() << "\n";
    }
  }

  {
    array_t x{1,{2,3}};
    std::cout << "#=" << x.size << "\n";
    for (std::size_t i = 0; i < x.size; ++i) {
      std::cout << "[" << i << "]=" << x[i].tostring() << "\n";
    }
  }

  invoke(test_f, { "foo" });
  invoke(test_f, { "foo", "bar", "baz", "qux" });
  // bind_each(test_f, { "foo", "bar", "baz" }, 0, make_sequence_t<3>());
  auto x = invoke([](const value_t& a, const array_t& v) -> array_t {
    std::cout << a.tostring() << " " << v.size << "\n";
    return { 42, "foo", "bar" };
  }, { "foo", "bar", "baz" });
  std::cout << "R=" << x.size << "\n"
    << x[0].tostring() << " "
    << x[1].tostring() << " "
    << x[2].tostring() << "\n";

  int v = 42;

  callable(test);
  callable([=](int x, int y) -> int {return x + v + y;});
  auto B = std::bind(test, 1, 2, 3, std::placeholders::_1);
  dump(B);
  // callable(B);
  auto F = std::function<void(int)>(B);
  dump(F);
  callable(F);
  callable(const_callable_t{});
  callable(mutable_callable_t{});
  // callable(42);
  // callable(not_callable_t{});

  {
    value_t v = [](const value_t& a, const value_t& b, const value_t& c) {
      std::cout << a.tostring() << b.tostring() << c.tostring() << "\n";
    };
    std::cout << v.tostring() << "\n";
    value_t x = type_t::function;
    std::cout << x.tostring() << "\n";

    call0(v, { "foo", "bar", "baz" });
    call0(x, { "foo", "bar", "baz" });
  }

  return 0;
}
