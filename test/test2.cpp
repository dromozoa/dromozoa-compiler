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

#include "runtime.hpp"

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
          << tostring(x) << " "
          << tostring(y) << " "
          << tostring(z) << "\n";
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
  std::cout << tostring(r) << "\n";
  r = 42;
  std::cout << tostring(r) << "\n";
  r = "foo";
  std::cout << tostring(r) << "\n";
  r = s;
  std::cout << tostring(r) << "\n";
  r = std::string("baz");
  std::cout << tostring(r) << "\n";
  r = {};
  std::cout << tostring(r) << "\n";
  r = type_t::table;
  std::cout << tostring(r) << "\n";

  {
    array_t x;
    std::cout << "#=" << x.size << "\n";
    for (std::size_t i = 0; i < x.size; ++i) {
      std::cout << "[" << i << "]=" << tostring(x[i]) << "\n";
    }
  }

  {
    array_t x{};
    std::cout << "#=" << x.size << "\n";
    for (std::size_t i = 0; i < x.size; ++i) {
      std::cout << "[" << i << "]=" << tostring(x[i]) << "\n";
    }
  }

  {
    array_t x(1);
    std::cout << "#=" << x.size << "\n";
    for (std::size_t i = 0; i < x.size; ++i) {
      std::cout << "[" << i << "]=" << tostring(x[i]) << "\n";
    }
  }

  {
    array_t x{1};
    std::cout << "#=" << x.size << "\n";
    for (std::size_t i = 0; i < x.size; ++i) {
      std::cout << "[" << i << "]=" << tostring(x[i]) << "\n";
    }
  }

  {
    array_t x{1,2};
    std::cout << "#=" << x.size << "\n";
    for (std::size_t i = 0; i < x.size; ++i) {
      std::cout << "[" << i << "]=" << tostring(x[i]) << "\n";
    }
  }

  {
    array_t x{1,{2,3}};
    std::cout << "#=" << x.size << "\n";
    for (std::size_t i = 0; i < x.size; ++i) {
      std::cout << "[" << i << "]=" << tostring(x[i]) << "\n";
    }
  }

  invoke(test_f, { "foo" });
  invoke(test_f, { "foo", "bar", "baz", "qux" });
  // bind_each(test_f, { "foo", "bar", "baz" }, 0, make_sequence_t<3>());
  auto x = invoke([](const value_t& a, const array_t& v) -> array_t {
    std::cout << tostring(a) << " " << v.size << "\n";
    return { 42, "foo", "bar" };
  }, { "foo", "bar", "baz" });
  std::cout << "R=" << x.size << "\n"
    << tostring(x[0]) << " "
    << tostring(x[1]) << " "
    << tostring(x[2]) << "\n";

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
      std::cout << tostring(a) << tostring(b) << tostring(c) << "\n";
    };
    std::cout << tostring(v) << "\n";
    value_t x = type_t::function;
    std::cout << tostring(x) << "\n";

    call0(v, { "foo", "bar", "baz", "qux" });
    call0(v, { "foo", "bar" });
    call0(x, { "foo", "bar", "baz", "qux" });
  }

  {
  }

  return 0;
}
