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

#include <cctype>
#include <cmath>
#include <exception>
#include <iomanip>
#include <sstream>
#include <utility>

#include "runtime.hpp"

namespace dromozoa {
  namespace runtime {
    namespace {
      inline int regexp_integer(const std::string& string) {
        int state = 6;
        for (const char c : string) {
          switch (state) {
            case 1: if      ( std::isspace(c))      { state = 2; }
                    else if ( isdigit(c))           { state = 3; }
                    else if ( c == 'X' || c == 'x') { state = 8; }
                    else                            { return 0;  } break;
            case 2: if      (!std::isspace(c))      { return 0;  } break;
            case 3: if      ( std::isspace(c))      { state = 2; }
                    else if (!std::isdigit(c))      { return 0;  } break;
            case 4: if      ( std::isspace(c))      { state = 5; }
                    else if (!std::isxdigit(c))     { return 0;  } break;
            case 5: if      (!std::isspace(c))      { return 0;  } break;
            case 6: if      ( c == '0')             { state = 1; }
                    else if ( std::isdigit(c))      { state = 3; }
                    else if ( c == '+' || c == '-') { state = 7; }
                    else if (!std::isspace(c))      { return 0;  } break;
            case 7: if      ( c == '0')             { state = 1; }
                    else if ( std::isdigit(c))      { state = 3; }
                    else                            { return 0;  } break;
            case 8: if      ( std::isxdigit(c))     { state = 4; }
                    else                            { return 0;  } break;
          }
        }
        switch (state) {
          case 1: case 2: case 3: return 1;
          case 4: case 5:         return 2;
          default:                return 0;
        }
      }

      inline bool to_number(const std::string& string, double& result) {
        try {
          const auto n = string.find_last_not_of(" \f\n\r\t\v");
          if (n != std::string::npos) {
            std::size_t i = 0;
            const auto number = std::stod(string, &i);
            if (i == n + 1) {
              result = number;
              return true;
            }
          }
        } catch (const std::exception&) {}
        return false;
      }

      inline std::string to_string(double number) {
        std::ostringstream out;
        out << std::setprecision(17) << number;
        return out.str();
      }
    }

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
          case type_t::thread:
            new (&self.thread_) std::shared_ptr<thread_t>(that.thread_);
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
          case type_t::thread:
            new (&self.thread_) std::shared_ptr<thread_t>(std::move(that.thread_));
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
          case type_t::thread:
            self.thread_.~shared_ptr();
            return;
        }
      }
    };

    value_t::value_t()
      : type_(type_t::nil) {}

    value_t::value_t(const value_t& that)
      : value_t() {
      access::copy_construct(*this, that);
    }

    value_t::value_t(value_t&& that)
      : value_t() {
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

    value_t::value_t(bool boolean)
      : type_(type_t::boolean) {
      boolean_ = boolean;
    }

    value_t::value_t(double number)
      : type_(type_t::number) {
      number_ = number;
    }

    value_t::value_t(const char* data)
      : type_(type_t::string) {
      new (&string_) std::shared_ptr<std::string>(std::make_shared<std::string>(data));
    }

    value_t::value_t(const char* data, std::size_t size)
      : type_(type_t::string) {
      new (&string_) std::shared_ptr<std::string>(std::make_shared<std::string>(data, size));
    }

    value_t::value_t(const std::string& string)
      : type_(type_t::string) {
      new (&string_) std::shared_ptr<std::string>(std::make_shared<std::string>(string));
    }

    value_t::value_t(std::string&& string)
      : type_(type_t::string) {
      new (&string_) std::shared_ptr<std::string>(std::make_shared<std::string>(std::move(string)));
    }

    value_t::value_t(std::shared_ptr<table_t> table)
      : type_(type_t::table) {
      new (&table_) std::shared_ptr<table_t>(table);
    }

    value_t::value_t(std::shared_ptr<function_t> function)
      : type_(type_t::function) {
      new (&function_) std::shared_ptr<function_t>(function);
    }

    value_t::value_t(std::shared_ptr<thread_t> thread)
      : type_(type_t::thread) {
      new (&thread_) std::shared_ptr<thread_t>(thread);
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
        case type_t::thread:
          return thread_ < that.thread_;
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
        case type_t::thread:
          return "thread";
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

    bool value_t::isthread() const {
      return type_ == type_t::thread;
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

    bool value_t::tonumber(double& result) const {
      if (isnumber()) {
        result = number_;
        return true;
      } else if (isstring()) {
        switch (regexp_integer(*string_)) {
          case 1: result = std::stoll(*string_, nullptr, 10); return true;
          case 2: result = std::stoll(*string_, nullptr, 16); return true;
        }
        double number = 0;
        if (to_number(*string_, number)) {
          result = number;
          return true;
        }
      }
      return false;
    }

    double value_t::checknumber() const {
      double result = 0;
      if (tonumber(result)) {
        return result;
      }
      throw value_t("number expected, got " + type());
    }

    std::int64_t value_t::checkinteger() const {
      if (isnumber()) {
        if (std::isfinite(number_) && number_ == std::floor(number_)) {
          return number_;
        }
        throw value_t("number has no integer representation");
      } else if (isstring()) {
        switch (regexp_integer(*string_)) {
          case 1: return std::stoll(*string_, nullptr, 10);
          case 2: return std::stoll(*string_, nullptr, 16);
        }
        double number = 0;
        if (to_number(*string_, number)) {
          if (std::isfinite(number) && number == std::floor(number)) {
            return number;
          }
          throw value_t("number has no integer representation");
        }
      }
      throw value_t("integer expected, got " + type());
    }

    std::string value_t::checkstring() const {
      if (isstring()) {
        return *string_;
      } else if (isnumber()) {
        return to_string(number_);
      }
      throw value_t("string expected, got " + type());
    }

    std::shared_ptr<table_t> value_t::checktable() const {
      if (istable()) {
        return table_;
      }
      throw value_t("table expected, got " + type());
    }

    std::shared_ptr<function_t> value_t::checkfunction() const {
      if (isfunction()) {
        return function_;
      }
      throw value_t("function expected, got " + type());
    }

    std::shared_ptr<thread_t> value_t::checkthread() const {
      if (isthread()) {
        return thread_;
      }
      throw value_t("thread expected, got " + type());
    }

    std::int64_t value_t::optinteger(std::int64_t d) const {
      if (isnil()) {
        return d;
      } else {
        return checkinteger();
      }
    }

    const value_t& value_t::rawget(const value_t& index) const {
      return checktable()->get(index);
    }

    std::int64_t value_t::rawlen() const {
      if (isstring()) {
        return string_->size();
      } else if (istable()) {
        for (std::int64_t i = 1; ; ++i) {
          if (rawget(i).isnil()) {
            return i - 1;
          }
        }
      }
      throw value_t("attempt to get length of a " + type() + " value");
    }

    void value_t::rawset(const value_t& index, const value_t& value) const {
      checktable()->set(index, value);
    }

    void value_t::rawset(const value_t& begin, const array_t& array) const {
      const auto table = checktable();
      std::int64_t index = begin.checkinteger();
      for (std::size_t i = 0; i < array.size(); ++i) {
        table->set(index++, array[i]);
      }
    }

    value_t NIL;
    value_t FALSE = false;
    value_t TRUE = true;

    array_t::array_t()
      : size_(0) {}

    array_t::array_t(std::size_t size)
      : array_t() {
      if (size > 0) {
        data_ = std::shared_ptr<value_t>(new value_t[size], std::default_delete<value_t[]>());
        size_ = size;
      }
    }

    value_t& array_t::operator[](std::size_t i) const {
      if (i < size_) {
        return data_.get()[i];
      } else {
        return NIL;
      }
    }

    std::size_t array_t::size() const {
      return size_;
    }

    array_t array_t::sub(std::size_t begin) const {
      if (size_ > begin) {
        array_t that(size_ - begin);
        std::size_t index = 0;
        for (std::size_t i = begin; i < size_; ++i) {
          that[index++] = (*this)[i];
        }
        return that;
      } else {
        return array_t();
      }
    }

    const value_t& table_t::get(const value_t& index) const {
      const auto i = map_.find(index);
      if (i == map_.end()) {
        return NIL;
      } else {
        return i->second;
      }
    }

    void table_t::set(const value_t& index, const value_t& value) {
      if (index.isnil()) {
        throw value_t("table index is nil");
      }
      if (value.isnil()) {
        map_.erase(index);
      } else {
        map_[index] = value;
      }
    }
  }
}
