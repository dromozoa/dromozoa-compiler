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

#include <cstddef>
#include <cstdint>
#include <functional>
#include <initializer_list>
#include <map>
#include <memory>
#include <string>

namespace dromozoa {
  namespace runtime {
    enum class type_t : std::uint8_t {
      nil,
      boolean,
      number,
      string,
      table,
      function,
    };

    class table_t;
    class function_t;

    class value_t {
      struct access;
    public:
      value_t();
      value_t(const value_t&);
      value_t(value_t&&);
      ~value_t();
      value_t& operator=(const value_t&);
      value_t& operator=(value_t&&);

      value_t(bool);
      value_t(double);
      value_t(const char*);
      value_t(const char*, std::size_t);
      value_t(const std::string&);
      value_t(std::string&&);
      value_t(std::shared_ptr<table_t>);
      value_t(std::shared_ptr<function_t>);

      bool operator<(const value_t&) const;

      std::string type() const;
      bool isnil() const;
      bool isboolean() const;
      bool isnumber() const;
      bool isstring() const;
      bool istable() const;
      bool isfunction() const;

      bool toboolean() const;
      bool tonumber(double& result) const;
      std::string tostring() const;

      double checknumber() const;
      std::int64_t checkinteger() const;
      std::string checkstring() const;
      std::shared_ptr<table_t> checktable() const;
      std::shared_ptr<function_t> checkfunction() const;

      std::int64_t optinteger(std::int64_t) const;

    private:
      type_t type_;
      union {
        bool boolean_;
        double number_;
        std::shared_ptr<std::string> string_;
        std::shared_ptr<table_t> table_;
        std::shared_ptr<function_t> function_;
      };
    };

    extern value_t NIL;
    extern value_t FALSE;
    extern value_t TRUE;

    class ref_t {
    public:
      ref_t();

    private:
      std::shared_ptr<value_t> data_;
    };

    class array_t {
    public:
      array_t();
      value_t& operator[](std::size_t) const;

    private:
      std::shared_ptr<value_t> data_;
      std::size_t size_;
    };

    class table_t {
    public:
      table_t();

    private:
      std::map<value_t, value_t> map_;
      value_t metatable_;
    };

    class function_t {
    public:
      virtual ~function_t();
      virtual std::function<void()> operator()(std::shared_ptr<function_t>, std::shared_ptr<function_t>, std::shared_ptr<function_t>, std::initializer_list<value_t>) = 0;
    };
  }
}

#endif
