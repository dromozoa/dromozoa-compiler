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
    template <class T>
    using decay_t = typename std::decay<T>::type;

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
    void bind_each(T&& function, const array_t& args, std::size_t i, sequence<T_i, T_j...>) {
      bind_each(
          std::bind(
              std::forward<T>(function),
              std::cref(args[i]),
              placeholder<T_j>()...),
          args,
          i + 1,
          sequence<(T_j - 1)...>());
    }

    template <class T>
    void bind_each(T function, const array_t&, std::size_t, sequence<>) {
      function();
    }

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
    struct function_traits
      : function_traits<decltype(&T::operator())> {};

    template <class T_result, class... T>
    struct function_traits<T_result(*)(T...)> {
      using result_type = T_result;
      using arguments_type = std::tuple<decay_t<T>...>;
    };

    template <class T_result, class T_class, class... T>
    struct function_traits<T_result(T_class::*)(T...)> {
      using result_type = T_result;
      using arguments_type = std::tuple<decay_t<T>...>;
    };

    template <class T_result, class T_class, class... T>
    struct function_traits<T_result(T_class::*)(T...) const> {
      using result_type = T_result;
      using arguments_type = std::tuple<decay_t<T>...>;
    };

    template <class T>
    using result_type_t = typename function_traits<T>::result_type;

    template <class T>
    using arguments_type_t = typename function_traits<T>::arguments_type;


    // template <class T>
    // struct closure_t : function_t {
    //   closure_t(const T& closure) : closure(closure) {};
    //   closure_t(T&& closure) : closure(std::move(closure)) {};

    //   virtual array_t operator()(array_t args) const {
    //     binder<T>::
    //     return (*this)(args.sub(0, T), args.sub(T));
    //   }

    //   T closure;
    // };

    // template <class T>
    // std::shared_ptr<closure_t<T>> make_closure(T&& closure, result_type_t<T>* = 0) {
    //   return std::make_shared<closure<T>>(std::forward(T));
    // }

    template <std::size_t T_i, std::size_t T_n, class = void>
    struct make_arguments {
      template <class T>
      static void each(const array_t&, T&) {}
    };

    template <std::size_t T_i, std::size_t T_n>
    struct make_arguments<T_i, T_n, enable_if_t<(T_i + 1 < T_n)>> {
      template <class T>
      static void each(const array_t& source, T& target) {
        convert(source, std::get<T_i>(target));
        make_arguments<T_i + 1, T_n>::each(source, target);
      }

      static void convert(const array_t& source, value_t& target) {
        target = source[T_i];
      }
    };

    template <std::size_t T_i, std::size_t T_n>
    struct make_arguments<T_i, T_n, enable_if_t<(T_i + 1 == T_n)>> {
      template <class T>
      static void each(const array_t& source, T& target) {
        convert(source, std::get<T_i>(target));
        make_arguments<T_i + 1, T_n>::each(source, target);
      }

      static void convert(const array_t& source, value_t& target) {
        target = source[T_i];
      }

      static void convert(const array_t& source, array_t& target) {
        target = source.sub(T_i);
      }
    };

    template <class T_result>
    struct invoker;

    template <>
    struct invoker<void> {
      template <class T, class T_args, int... T_i>
      static array_t invoke(T function, T_args args, sequence<T_i...>) {
        function(std::get<T_i>(args)...);
        return {};
      }
    };

    template <>
    struct invoker<value_t> {
      template <class T, class T_args, int... T_i>
      static array_t invoke(T function, T_args args, sequence<T_i...>) {
        return { function(std::get<T_i>(args)...) };
      }
    };

    template <>
    struct invoker<array_t> {
      template <class T, class T_args, int... T_i>
      static array_t invoke(T function, T_args args, sequence<T_i...>) {
        return function(std::get<T_i>(args)...);
      }
    };

    template <class T>
    inline array_t invoke(T f, const array_t& source) {
      arguments_type_t<T> target;
      static constexpr std::size_t size = std::tuple_size<arguments_type_t<T>>::value;
      make_arguments<0, size>::each(source, target);
      return invoker<result_type_t<T>>::invoke(f, target, make_sequence_t<size>());
    }

    template <class T>
    inline void make_function(T, result_type_t<T>* = 0) {
      std::cout << "#f=" << std::tuple_size<arguments_type_t<T>>::value << "\n";
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

  make_function([](int,int){});
  make_function(std::function<void(int,int,int,int)>(test));
  make_function(test);

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

  return 0;
}
