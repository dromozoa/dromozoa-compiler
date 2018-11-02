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

#ifndef DROMOZOA_COMPILER_RUNTIME_CXX_VALUE_HPP
#define DROMOZOA_COMPILER_RUNTIME_CXX_VALUE_HPP

#include <cstddef>
#include <cstdint>
#include <functional>
#include <initializer_list>
#include <map>
#include <memory>
#include <string>
#include <tuple>
#include <type_traits>

namespace dromozoa {
  namespace runtime {
    template <bool T_condition, class T = void>
    using enable_if_t = typename std::enable_if<T_condition, T>::type;

    enum struct mode_t : std::uint8_t {
      variable,
      constant,
    };

    enum struct type_t : std::uint8_t {
      nil,
      boolean,
      number,
      string,
      table,
      function,
    };

    using string_ptr = std::shared_ptr<std::string>;
    struct table_t;
    using table_ptr = std::shared_ptr<table_t>;
    struct function_t;
    using function_ptr = std::shared_ptr<function_t>;

    struct value_t {
      value_t();
      value_t(const value_t&);
      value_t(value_t&&);
      ~value_t();
      value_t& operator=(const value_t&);
      value_t& operator=(value_t&&);

      value_t(type_t);
      value_t(bool);
      value_t(double);
      value_t(const char*);
      value_t(const char*, size_t);
      value_t(const std::string&);
      value_t(std::string&&);
      value_t(function_ptr);

      template <class T>
      value_t(T value, enable_if_t<std::is_integral<T>::value>* = 0)
        : value_t(static_cast<double>(value)) {}

      template <class T>
      value_t(T value, enable_if_t<std::is_convertible<T, function_ptr>::value>* = 0)
        : value_t(static_cast<function_ptr>(value)) {}

      template <class T>
      value_t(T, enable_if_t<(!std::is_integral<T>::value && !std::is_convertible<T, function_ptr>::value)>* = 0);

      bool operator<(const value_t&) const;

      bool is_nil() const;
      bool is_boolean() const;
      bool is_number() const;
      bool is_string() const;
      bool is_table() const;
      bool is_function() const;

      bool toboolean() const;
      bool tonumber(double&) const;
      bool tointeger(int64_t&) const;
      bool tostring(std::string&) const;
      double checknumber() const;
      int64_t checkinteger() const;
      std::string checkstring() const;
      table_ptr checktable() const;

      const mode_t mode;
      type_t type;
      union {
        bool boolean;
        double number;
        string_ptr string;
        table_ptr table;
        function_ptr function;
      };
    };

    extern value_t NIL;
    extern value_t FALSE;
    extern value_t TRUE;
    extern value_t string_metatable;
    extern value_t env;

    struct array_t {
      array_t();
      array_t(std::size_t);
      array_t(std::initializer_list<value_t>);
      array_t(std::initializer_list<value_t>, array_t);
      array_t(const value_t&, array_t);
      value_t& operator[](std::size_t) const;
      array_t sub(std::size_t) const;
      array_t sub(std::size_t, std::size_t) const;

      std::shared_ptr<value_t> data;
      std::size_t size;
    };

    struct upvalue_t {
      upvalue_t();
      upvalue_t(array_t array, std::size_t index);
      value_t& operator*() const;

      array_t array;
      std::size_t index;
    };

    struct uparray_t {
      uparray_t();
      uparray_t(std::initializer_list<upvalue_t>);
      upvalue_t& operator[](std::size_t) const;

      std::shared_ptr<upvalue_t> data;
      std::size_t size;
    };

    struct table_t {
      const value_t& get(const value_t&) const;
      void set(const value_t&, const value_t&);

      std::map<value_t, value_t> map;
      value_t metatable;
    };

    struct function_t {
      virtual ~function_t() {}
      virtual array_t operator()(array_t) = 0;
    };

    template <std::size_t T>
    struct proto_t : function_t {
      virtual array_t operator()(array_t, array_t) const = 0;
      virtual array_t operator()(array_t args) {
        return (*this)(args.sub(0, T), args.sub(T));
      }
    };

    const value_t& rawget(const value_t&, const value_t&);
    const value_t& rawset(const value_t&, const value_t&, const value_t&);
    const value_t& getmetafield(const value_t&, const value_t&);
    const value_t& getmetatable(const value_t&);
    const value_t& setmetatable(const value_t&, const value_t&);
    value_t gettable(const value_t&, const value_t&);
    void settable(const value_t&, const value_t&, const value_t&);
    void setlist(const value_t&, std::size_t, const value_t&);
    void setlist(const value_t&, std::size_t, const array_t&);

    array_t call(const value_t&, const array_t& args);
    value_t call1(const value_t&, const array_t& args);
    void call0(const value_t&, const array_t& args);

    std::string type(const value_t&);
    std::string tostring(const value_t&);
    int64_t len(const value_t&);
    bool eq(const value_t&, const value_t&);
    bool lt(const value_t&, const value_t&);
    bool le(const value_t&, const value_t&);
  }
}

namespace dromozoa {
  namespace runtime {
    template <class T>
    using decay_t = typename std::decay<T>::type;

    template <int...>
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

    template <class T>
    struct function_traits
      : function_traits<decltype(&T::operator())> {};

    template <class T_result, class... T>
    struct function_traits<T_result(*)(T...)> {
      using result_type = T_result;
      using arguments_type = std::tuple<decay_t<T>...>;
      static constexpr std::size_t arity = sizeof...(T);
    };

    template <class T_result, class T_class, class... T>
    struct function_traits<T_result(T_class::*)(T...)> {
      using result_type = T_result;
      using arguments_type = std::tuple<decay_t<T>...>;
      static constexpr std::size_t arity = sizeof...(T);
    };

    template <class T_result, class T_class, class... T>
    struct function_traits<T_result(T_class::*)(T...) const> {
      using result_type = T_result;
      using arguments_type = std::tuple<decay_t<T>...>;
      static constexpr std::size_t arity = sizeof...(T);
    };

    template <class T>
    using result_type_t = typename function_traits<T>::result_type;

    template <class T>
    using arguments_type_t = typename function_traits<T>::arguments_type;

    template <std::size_t T_i, std::size_t T_n, class = void>
    struct arguments_builder {
      template <class T>
      static void build(const array_t&, T&) {}
    };

    template <std::size_t T_i, std::size_t T_n>
    struct arguments_builder<T_i, T_n, enable_if_t<(T_i + 1 < T_n)>> {
      template <class T>
      static void build(const array_t& source, T& target) {
        convert(source, std::get<T_i>(target));
        arguments_builder<T_i + 1, T_n>::build(source, target);
      }

      static void convert(const array_t& source, value_t& target) {
        target = source[T_i];
      }
    };

    template <std::size_t T_i, std::size_t T_n>
    struct arguments_builder<T_i, T_n, enable_if_t<(T_i + 1 == T_n)>> {
      template <class T>
      static void build(const array_t& source, T& target) {
        convert(source, std::get<T_i>(target));
        arguments_builder<T_i + 1, T_n>::build(source, target);
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
      static array_t invoke(T function, const T_args& args, sequence<T_i...>) {
        function(std::get<T_i>(args)...);
        return {};
      }
    };

    template <>
    struct invoker<value_t> {
      template <class T, class T_args, int... T_i>
      static array_t invoke(T function, const T_args& args, sequence<T_i...>) {
        return { function(std::get<T_i>(args)...) };
      }
    };

    template <>
    struct invoker<array_t> {
      template <class T, class T_args, int... T_i>
      static array_t invoke(T function, const T_args& args, sequence<T_i...>) {
        return function(std::get<T_i>(args)...);
      }
    };

    template <class T>
    inline array_t invoke(T function, const array_t& source) {
      static constexpr std::size_t arity = function_traits<T>::arity;
      arguments_type_t<T> target;
      arguments_builder<0, arity>::build(source, target);
      return invoker<result_type_t<T>>::invoke(function, target, make_sequence_t<arity>());
    }

    template <class T>
    struct closure_t : function_t {
      closure_t(T function) : function(function) {}
      virtual array_t operator()(array_t args) {
        return invoke(function, args);
      }
      T function;
    };

    template <class T>
    inline value_t::value_t(T function, enable_if_t<(!std::is_integral<T>::value && !std::is_convertible<T, function_ptr>::value)>*)
      : mode(mode_t::constant),
        type(type_t::function) {
      new (&this->function) function_ptr(std::make_shared<closure_t<T>>(function));
    }
  }
}

#endif
