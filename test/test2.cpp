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
#include <iomanip>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <utility>

namespace dromozoa {
  namespace runtime {
    template <int... T>
    struct sequence {};

    template <int T_n, class T = sequence<>>
    struct make_sequence;

    template <int T_n, class T = sequence<>>
    using make_sequence_t = typename make_sequence<T_n, T>::type;

    template <int T_n, int... T>
    struct make_sequence<T_n, sequence<T...>> {
      using type = make_sequence_t<T_n - 1, sequence<T_n - 1, T...>>;
    };

    template <int... T>
    struct make_sequence<0, sequence<T...>> {
      using type = sequence<T...>;
    };

    template <int T_i>
    struct placeholder {};

    template <class T, int T_i, int... T_j>
    void bind(T f, int index, sequence<T_i, T_j...>) {
      bind(
          std::bind(
              f,
              index,
              placeholder<T_j>()...),
          index + 1,
          sequence<(T_j - 1)...>());
    }

    template <class T>
    void bind(T f, int index, sequence<>) {
      f(index);
    }

    inline void test(int x, int y, int z, int w) {
      std::cout
          << x << " "
          << y << " "
          << z << " "
          << w << "\n";
    }
  }
}

namespace std {
  template <int T>
  struct is_placeholder<dromozoa::runtime::placeholder<T>>
    : std::integral_constant<int, T> {};
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
    array_t x{{1,2},{3,4}};
    std::cout << "#=" << x.size << "\n";
    for (std::size_t i = 0; i < x.size; ++i) {
      std::cout << "[" << i << "]=" << tostring(x[i]) << "\n";
    }
  }

  return 0;
}
