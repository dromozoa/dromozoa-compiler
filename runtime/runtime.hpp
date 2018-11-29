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

#ifndef DROMOZOA_COMPILER_RUNTIME_HPP
#define DROMOZOA_COMPILER_RUNTIME_HPP

#include <cstdint>
#include <memory>
#include <string>

namespace dromozoa {
  namespace runtime {
    enum struct type_t : std::uint8_t {
      nil,
      boolean,
      number,
      string,
      table,
      function,
    };

    struct table_t;
    struct function_t;

    struct value_t {
      value_t& operator*();

      type_t type;
      union {
        bool boolean;
        double number;
        std::shared_ptr<std::string> string;
        std::shared_ptr<table_t> table;
        std::shared_ptr<function_t> function;
      };
    };

    struct ref_t {
      value_t& operator*();

      std::shared_ptr<value_t> value;
    };

    struct tuple_t;
  }
}

#endif
