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

#include <iomanip>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <utility>

#include "runtime_cxx_value.hpp"

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

    value_t::value_t()
      : mode(mode_t::variable),
        type(type_t::nil) {}

    value_t::value_t(const value_t& that)
      : value_t() {
      copy_construct(*this, that);
    }

    value_t::value_t(value_t&& that)
      : value_t() {
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

    value_t::value_t(type_t type)
      : mode(mode_t::constant),
        type(type) {
      switch (type) {
        case type_t::nil:
          break;
        case type_t::boolean:
          boolean = false;
          break;
        case type_t::number:
          number = 0;
          break;
        case type_t::string:
          new (&string) string_ptr(std::make_shared<std::string>());
          break;
        case type_t::table:
          new (&table) table_ptr(std::make_shared<table_t>());
          break;
        case type_t::function:
          // TODO function = noop;
          function = nullptr;
          break;
        default:
          throw std::runtime_error("unreachable code");
      }
    }

    value_t::value_t(bool boolean)
      : mode(mode_t::constant),
        type(type_t::boolean) {
      this->boolean = boolean;
    }

    value_t::value_t(double number)
      : mode(mode_t::constant),
        type(type_t::number) {
      this->number = number;
    }

    value_t::value_t(const char* data)
      : mode(mode_t::constant),
        type(type_t::string) {
      new (&this->string) string_ptr(std::make_shared<std::string>(data));
    }

    value_t::value_t(const char* data, std::size_t size)
      : mode(mode_t::constant),
        type(type_t::string) {
      new (&this->string) string_ptr(std::make_shared<std::string>(data, size));
    }

    value_t::value_t(const std::string& string)
      : mode(mode_t::constant),
        type(type_t::string) {
      new (&this->string) string_ptr(std::make_shared<std::string>(string));
    }

    value_t::value_t(std::string&& string)
      : mode(mode_t::constant),
        type(type_t::string) {
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

    bool value_t::is_nil() const {
      return type == type_t::nil;
    }

    bool value_t::is_boolean() const {
      return type == type_t::boolean;
    }

    bool value_t::is_number() const {
      return type == type_t::number;
    }

    bool value_t::is_string() const {
      return type == type_t::string;
    }

    bool value_t::is_table() const {
      return type == type_t::table;
    }

    bool value_t::is_function() const {
      return type == type_t::function;
    }

    bool value_t::is_false() const {
      return is_boolean() && !boolean;
    }

    bool value_t::is_true() const {
      return is_boolean() && boolean;
    }

    bool value_t::is_nil_or_false() const {
      return is_nil() || is_false();
    }

    array_t::array_t()
      : size() {}

    array_t::array_t(std::size_t n)
      : array_t() {
      if (n > 0) {
        data = std::shared_ptr<value_t>(new value_t[n], std::default_delete<value_t[]>());
        size = n;
      }
    }

    array_t::array_t(std::initializer_list<value_t> source)
      : array_t() {
      const auto n = source.size();
      if (n > 0) {
        data = std::shared_ptr<value_t>(new value_t[n], std::default_delete<value_t[]>());
        size = n;
        auto* ptr = data.get();
        for (const auto& value : source) {
          *ptr++ = value;
        }
      }
    }

    array_t::array_t(array_t a, array_t b) {
      const auto n = a.size + b.size;
      if (n > 0) {
        data = std::shared_ptr<value_t>(new value_t[n], std::default_delete<value_t[]>());
        size = n;
        auto* ptr = data.get();
        for (std::size_t i = 0; i < a.size; ++i) {
          *ptr++ = a.data.get()[i];
        }
        for (std::size_t i = 0; i < b.size; ++i) {
          *ptr++ = b.data.get()[i];
        }
      }
    }

    value_t& array_t::operator[](std::size_t i) const {
      if (i < size) {
        return data.get()[i];
      } else {
        return NIL;
      }
    }

    array_t array_t::sub(std::size_t begin) const {
      if (size > begin) {
        array_t that(size - begin);
        auto* ptr = that.data.get();
        for (std::size_t i = begin; i < size; ++i) {
          *ptr++ = data.get()[i];
        }
        return that;
      } else {
        return {};
      }
    }

    array_t array_t::sub(std::size_t begin, std::size_t end) const {
      if (end > begin) {
        array_t that(end - begin);
        auto* ptr = that.data.get();
        for (std::size_t i = begin; i < end; ++i) {
          *ptr++ = (*this)[i];
        }
        return that;
      } else {
        return {};
      }
    }

    std::string tostring(const value_t& self) {
      switch (self.type) {
        case type_t::nil:
          return "nil";
        case type_t::boolean:
          return self.boolean ? "true" : "false";
        case type_t::number:
          {
            std::ostringstream out;
            out << std::setprecision(17) << self.number;
            return out.str();
          }
        case type_t::string:
          return *self.string;
        case type_t::table:
          {
            // TODO metatable
            std::ostringstream out;
            out << "table: " << self.table.get();
            return out.str();
          }
        case type_t::function:
          {
            std::ostringstream out;
            out << "function: " << self.function.get();
            return out.str();
          }
        default:
          throw std::runtime_error("unreachable code");
      }
    }
  }
}
