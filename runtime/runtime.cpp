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
// You should have received a copy of the GNU General Public License
// along with dromozoa-compiler.  If not, see <http://www.gnu.org/licenses/>.

#include <utility>

#include "runtime.hpp"

namespace dromozoa {
  namespace runtime {
    value_t NIL;
    value_t FALSE = false;
    value_t TRUE = true;

    struct value_t::access {
      static void copy_construct(value_t& self, const value_t& that) {
        self.type_ = that.type_;
        switch (self.type_) {
          case type_t::nil:
            return;
          case type_t::boolean:
            self.boolean_ = that.boolean_;
            return;
          case type_t::number:
            self.number_ = that.number_;
            return;
          case type_t::string:
            new (&self.string_) std::shared_ptr<std::string>(that.string_);
            return;
          case type_t::table:
            new (&self.table_) std::shared_ptr<table_t>(that.table_);
            return;
          case type_t::function:
            new (&self.function_) std::shared_ptr<function_t>(that.function_);
            return;
        }
      }

      static void move_construct(value_t& self, value_t&& that) {
        self.type_ = that.type_;
        that.type_ = type_t::nil;
        switch (self.type_) {
          case type_t::nil:
            return;
          case type_t::boolean:
            self.boolean_ = that.boolean_;
            return;
          case type_t::number:
            self.number_ = that.number_;
            return;
          case type_t::string:
            new (&self.string_) std::shared_ptr<std::string>(std::move(that.string_));
            return;
          case type_t::table:
            new (&self.table_) std::shared_ptr<table_t>(std::move(that.table_));
            return;
          case type_t::function:
            new (&self.function_) std::shared_ptr<function_t>(std::move(that.function_));
            return;
        }
      }

      static void destruct(value_t& self) {
        switch (self.type_) {
          case type_t::nil:
            return;
          case type_t::boolean:
            return;
          case type_t::number:
            return;
          case type_t::string:
            self.string_.~shared_ptr();
            return;
          case type_t::table:
            self.table_.~shared_ptr();
            return;
          case type_t::function:
            self.function_.~shared_ptr();
            return;
        }
      }
    };

    value_t::value_t() : type_(type_t::nil) {}

    value_t::value_t(const value_t& that) : value_t() {
      access::copy_construct(*this, that);
    }

    value_t::value_t(value_t&& that) : value_t() {
      access::move_construct(*this, std::move(that));
    }

    value_t::~value_t() {
      access::destruct(*this);
    }

    value_t& value_t::operator=(const value_t& that) {
      access::destruct(*this);
      access::copy_construct(*this, that);
      return *this;
    }

    value_t& value_t::operator=(value_t&& that) {
      access::destruct(*this);
      access::move_construct(*this, std::move(that));
      return *this;
    }

    value_t::value_t(bool boolean) : type_(type_t::boolean) {
      boolean_ = boolean;
    }

    value_t::value_t(double number) : type_(type_t::number) {
      number_ = number;
    }

    value_t::value_t(const char* data) : type_(type_t::string) {
      new (&string_) std::shared_ptr<std::string>(std::make_shared<std::string>(data));
    }

    value_t::value_t(const char* data, std::size_t size) : type_(type_t::string) {
      new (&string_) std::shared_ptr<std::string>(std::make_shared<std::string>(data, size));
    }

    value_t::value_t(const std::string& string) : type_(type_t::string) {
      new (&string_) std::shared_ptr<std::string>(std::make_shared<std::string>(string));
    }

    value_t::value_t(std::string&& string) : type_(type_t::string) {
      new (&string_) std::shared_ptr<std::string>(std::make_shared<std::string>(std::move(string)));
    }

    value_t::value_t(std::shared_ptr<table_t> table) : type_(type_t::table) {
      new (&table_) std::shared_ptr<table_t>(table);
    }

    value_t::value_t(std::shared_ptr<function_t> function) : type_(type_t::function) {
      new (&function_) std::shared_ptr<function_t>(function);
    }

    bool value_t::operator<(const value_t& that) const {
      if (type_ != that.type_) {
        return type_ < that.type_;
      }
      switch (type_) {
        case type_t::nil:
          return false;
        case type_t::boolean:
          return boolean_ < that.boolean_;
        case type_t::number:
          return number_ < that.number_;
        case type_t::string:
          return *string_ < *that.string_;
        case type_t::table:
          return table_ < that.table_;
        case type_t::function:
          return function_ < that.function_;
      }
    }

    std::string value_t::type() const {
      switch (type_) {
        case type_t::nil:
          return "nil";
        case type_t::boolean:
          return "boolean";
        case type_t::number:
          return "number";
        case type_t::string:
          return "string";
        case type_t::table:
          return "table";
        case type_t::function:
          return "function";
      }
    }

    bool value_t::isnil() const {
      return type_ == type_t::nil;
    }

    bool value_t::isboolean() const {
      return type_ == type_t::boolean;
    }

    bool value_t::isnumber() const {
      return type_ == type_t::number;
    }

    bool value_t::isstring() const {
      return type_ == type_t::string;
    }

    bool value_t::istable() const {
      return type_ == type_t::table;
    }

    bool value_t::isfunction() const {
      return type_ == type_t::function;
    }

    bool value_t::toboolean() const {
      if (isnil()) {
        return false;
      } else if (isboolean()) {
        return boolean_;
      } else {
        return true;
      }
    }

    bool tonumber(double& result) const {
      if (isnumber()) {
        result = number_;
        return true;
      } else if (isstring()) {

      }
      return false;
    }
  }
}
