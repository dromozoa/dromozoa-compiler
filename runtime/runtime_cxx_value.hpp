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
#include <memory>
#include <map>
#include <string>

namespace dromozoa {
  namespace runtime {
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

      value_t(bool);
      value_t(double);
      value_t(const char*);
      value_t(const char*, size_t);
      value_t(const std::string&);
      value_t(std::string&&);

      bool operator<(const value_t&) const;

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

    struct table_t {
      using map_t = std::map<value_t, value_t>;
      map_t map;
      table_ptr metatable;
    };

    struct array_t {
      array_t();
      array_t(std::size_t);
      value_t& operator[](std::size_t);

      std::shared_ptr<value_t> data;
      std::size_t size;
    };

    struct function_t {
      virtual ~function_t();
      virtual void operator()(array_t A, array_t V, array_t S) = 0;

      std::size_t argc;
      bool vararg;
    };
  }
}

#endif
