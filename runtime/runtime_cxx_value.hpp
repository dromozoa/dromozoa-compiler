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
#include <initializer_list>
#include <map>
#include <memory>
#include <string>
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

      template <typename T>
      value_t(T value, enable_if_t<std::is_integral<T>::value>* = 0)
        : value_t(static_cast<double>(value)) {}

      bool operator<(const value_t&) const;

      bool is_nil() const;
      bool is_boolean() const;
      bool is_number() const;
      bool is_string() const;
      bool is_table() const;
      bool is_function() const;
      bool is_false() const;
      bool is_true() const;
      bool is_nil_or_false() const;

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

    static value_t NIL = type_t::nil;
    static value_t FALSE = false;
    static value_t TRUE = true;

    struct array_t {
      array_t();
      array_t(std::size_t);
      array_t(std::initializer_list<value_t>);
      array_t(array_t, array_t);

      value_t& operator[](std::size_t) const;
      array_t sub(std::size_t) const;
      array_t sub(std::size_t, std::size_t) const;

      std::shared_ptr<value_t> data;
      std::size_t size;
    };

    struct table_t {
      using map_t = std::map<value_t, value_t>;
      map_t map;
      table_ptr metatable;
    };

    struct function_t {
      virtual ~function_t();
      virtual array_t operator()(array_t) const = 0;
    };

    template <std::size_t T>
    struct proto_t : function_t {
      virtual array_t operator()(array_t, array_t) const = 0;
      virtual array_t operator()(array_t args) const {
        return (*this)(args.sub(0, T), args.sub(T));
      }
    };

    const value_t& getmetafield(const value_t&);
    std::string tostring(const value_t&);
  }
}

#endif
