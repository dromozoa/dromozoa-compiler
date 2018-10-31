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

#include <utility>

#include <iostream>
#include <stdexcept>

namespace dromozoa {
  namespace runtime {
    namespace {
      void copy_construct(value_t& self, const value_t& that) {
        self.type = that.type;
        switch (self.type) {
          case type_t::nil:
            break;
          case type_t::boolean:
            self.boolean = that.boolean;
            break;
          case type_t::number:
            self.number = that.number;
            break;
          case type_t::string:
            new (&self.string) string_ptr(that.string);
            break;
          case type_t::table:
            new (&self.table) table_ptr(that.table);
            break;
          case type_t::function:
            new (&self.function) function_ptr(that.function);
            break;
          default:
            throw std::runtime_error("unreachable code");
        }
      }

      void move_construct(value_t& self, value_t&& that) {
        self.type = that.type;
        that.type = type_t::nil;
        switch (self.type) {
          case type_t::nil:
            break;
          case type_t::boolean:
            self.boolean = that.boolean;
            break;
          case type_t::number:
            self.number = that.number;
            break;
          case type_t::string:
            new (&self.string) string_ptr(std::move(that.string));
            break;
          case type_t::table:
            new (&self.table) table_ptr(std::move(that.table));
            break;
          case type_t::function:
            new (&self.function) function_ptr(std::move(that.function));
            break;
          default:
            throw std::runtime_error("unreachable code");
        }
      }

      void destruct(value_t& self) {
        switch (self.type) {
          case type_t::nil:
            break;
          case type_t::boolean:
            break;
          case type_t::number:
            break;
          case type_t::string:
            self.string.~shared_ptr();
            break;
          case type_t::table:
            self.table.~shared_ptr();
            break;
          case type_t::function:
            self.function.~shared_ptr();
            break;
          default:
            throw std::runtime_error("unreachable code");
        }
      }
    }

    value_t::value_t() : mode(mode_t::variable), type(type_t::nil) {}

    value_t::value_t(const value_t& that) : value_t() {
      copy_construct(*this, that);
    }

    value_t::value_t(value_t&& that) : value_t() {
      move_construct(*this, std::move(that));
    }

    value_t::~value_t() {
      destruct(*this);
    }

    value_t& value_t::operator=(const value_t& that) {
      if (mode == mode_t::constant) {
        throw std::runtime_error("cannot assign to constant value");
      }
      destruct(*this);
      copy_construct(*this, that);
      return *this;
    }

    value_t& value_t::operator=(value_t&& that) {
      if (mode == mode_t::constant) {
        throw std::runtime_error("cannot assign to constant value");
      }
      destruct(*this);
      move_construct(*this, std::move(that));
      return *this;
    }

    value_t::value_t(bool boolean) : mode(mode_t::constant), type(type_t::boolean) {
      this->boolean = boolean;
    }

    value_t::value_t(double number) : mode(mode_t::constant), type(type_t::number) {
      this->number = number;
    }

    value_t::value_t(const char* data) : mode(mode_t::constant), type(type_t::string) {
      new (&this->string) string_ptr(std::make_shared<std::string>(data));
    }

    value_t::value_t(const char* data, std::size_t size) : mode(mode_t::constant), type(type_t::string) {
      new (&this->string) string_ptr(std::make_shared<std::string>(data, size));
    }

    value_t::value_t(const std::string& string) : mode(mode_t::constant), type(type_t::string) {
      new (&this->string) string_ptr(std::make_shared<std::string>(string));
    }

    value_t::value_t(std::string&& string) : mode(mode_t::constant), type(type_t::string) {
      new (&this->string) string_ptr(std::make_shared<std::string>(std::move(string)));
    }

    bool value_t::operator<(const value_t& that) const {
      if (type != that.type) {
        return type < that.type;
      }
      switch (type) {
        case type_t::nil:
          return false;
        case type_t::boolean:
          return boolean < that.boolean;
        case type_t::number:
          return number < that.number;
        case type_t::string:
          return string < that.string;
        case type_t::table:
          return table < that.table;
        case type_t::function:
          return function < that.function;
        default:
          throw std::runtime_error("unreachable code");
      }
    }

    array_t::array_t()
      : size() {}

    array_t::array_t(std::size_t size)
      : data(new value_t[size], std::default_delete<value_t[]>()),
        size(size) {}
  }
}

int main(int, char*[]) {
  using namespace dromozoa::runtime;
  std::cout << sizeof(value_t) << "\n";

  std::string s = "bar";
  value_t r;
  r = "foo";
  r = s;
  r = std::string("baz");
  std::cout
    << static_cast<int>(r.mode) << " "
    << static_cast<int>(r.type) << "\n";

  return 0;
}
