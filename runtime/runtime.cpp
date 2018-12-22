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
#include <iostream>
#include <sstream>
#include <utility>

#include "runtime.hpp"

namespace dromozoa {
  namespace runtime {
    namespace {
      template <class T>
      inline value_t* copy(value_t* result, const T& range) {
        return std::copy(range.begin(), range.end(), result);
      }

      inline value_t* copy(value_t* result, const value_t& value) {
        *result = value;
        ++result;
        return result;
      }

      inline value_t* copy(value_t* result, const value_t* begin, const value_t* end) {
        return std::copy(begin, end, result);
      }

      inline int regexp_integer(const std::string& string) {
        int state = 6;
        for (const char c : string) {
          switch (state) {
            case 1: if      ( std::isspace(c))      { state = 2; }
                    else if ( isdigit(c))           { state = 3; }
                    else if ( c == 'X' || c == 'x') { state = 8; }
                    else                            { return  0; } break;
            case 2: if      (!std::isspace(c))      { return  0; } break;
            case 3: if      ( std::isspace(c))      { state = 2; }
                    else if (!std::isdigit(c))      { return  0; } break;
            case 4: if      ( std::isspace(c))      { state = 5; }
                    else if (!std::isxdigit(c))     { return  0; } break;
            case 5: if      (!std::isspace(c))      { return  0; } break;
            case 6: if      ( c == '0')             { state = 1; }
                    else if ( std::isdigit(c))      { state = 3; }
                    else if ( c == '+' || c == '-') { state = 7; }
                    else if (!std::isspace(c))      { return  0; } break;
            case 7: if      ( c == '0')             { state = 1; }
                    else if ( std::isdigit(c))      { state = 3; }
                    else                            { return  0; } break;
            case 8: if      ( std::isxdigit(c))     { state = 4; }
                    else                            { return  0; } break;
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

    array_t::array_t()
      : size_(0) {}

    array_t::array_t(std::initializer_list<value_t> data)
      : size_(data.size()) {
      if (size_ > 0) {
        data_ = std::shared_ptr<value_t>(new value_t[size_], std::default_delete<value_t[]>());
        copy(data_.get(), data);
      }
    }

    array_t::array_t(std::initializer_list<value_t> data, const array_t& that)
      : size_(data.size() + that.size()) {
      if (size_ > 0) {
        data_ = std::shared_ptr<value_t>(new value_t[size_], std::default_delete<value_t[]>());
        copy(copy(data_.get(), data), that);
      }
    }

    array_t::array_t(const value_t& value, const array_t& that)
      : size_(1 + that.size()) {
      data_ = std::shared_ptr<value_t>(new value_t[size_], std::default_delete<value_t[]>());
      copy(copy(data_.get(), value), that);
    }

    const value_t* array_t::begin() const {
      return data_.get();
    }

    const value_t* array_t::end() const {
      return data_.get() + size_;
    }

    const value_t& array_t::operator[](std::size_t i) const {
      if (i < size_) {
        return data_.get()[i];
      } else {
        return NIL;
      }
    }

    std::size_t array_t::size() const {
      return size_;
    }

    array_t array_t::slice(std::size_t first) const {
      if (size_ > first) {
        array_t that;
        that.size_ = size_ - first;
        that.data_ = std::shared_ptr<value_t>(new value_t[that.size_], std::default_delete<value_t[]>());
        copy(that.data_.get(), begin() + first, end());
        return that;
      } else {
        return {};
      }
    }

    state_t::state_t()
      : string_metatable_(std::make_shared<table_t>()),
        env_(std::make_shared<table_t>()) {}

    std::shared_ptr<table_t> state_t::string_metatable() const {
      return string_metatable_;
    };

    std::shared_ptr<table_t> state_t::env() const {
      return env_;
    };

    void state_t::open_base() {
      env_->set("tostring", make_function([](continuation_t k, state_t state, array_t args) {
        return k(state, { "-" });
      }));
    }

    void state_t::open_io() {
      value_t module { std::make_shared<table_t>() };

      module.rawset("write", make_function([](continuation_t k, state_t state, array_t args) {
        for (const auto& value : args) {
          std::cout << value.checkstring();
        }
        return k(state, {});
      }));

      env_->set("io", module);
    }

    void state_t::open_string() {
    }

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
      : type_(type_t::boolean),
        boolean_(boolean) {}

    value_t::value_t(double number)
      : type_(type_t::number),
        number_(number) {}

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

    const value_t& value_t::rawget(const value_t& index) const {
      return checktable()->get(index);
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

    const value_t& value_t::getmetafield(const state_t& state, const value_t& event) const {
      if (isstring()) {
        return state.string_metatable()->get(event);
      } else if (istable()) {
        const auto metatable = table_->getmetatable();
        if (metatable.istable()) {
          return metatable.rawget(event);
        }
      }
      return NIL;
    }

    std::shared_ptr<thunk_t> value_t::call(continuation_t k, state_t state, array_t args) const {
      if (isfunction()) {
        return (*checkfunction())(k, state, args);
      } else {
        const auto& field = getmetafield(state, "__call");
        if (field.isfunction()) {
          return (*field.checkfunction())(k, state, array_t(*this, args));
        }
      }
      throw value_t("attempt to call a " + type() + " value");
    }

    std::shared_ptr<thunk_t> value_t::gettable(continuation_t k, state_t state, const value_t& index) const {
      if (istable()) {
        const auto& result = rawget(index);
        if (!result.isnil()) {
          return k(state, { result });
        }
      }
      const auto& field = getmetafield(state, "__index");
      if (field.isnil()) {
        return k(state, { NIL });
      } else if (field.isfunction()) {
        return field.call(k, state, { *this, index });
      } else {
        return field.gettable(k, state, index);
      }
    }

    const value_t NIL;
    const value_t FALSE = false;
    const value_t TRUE = true;

    var_t::var_t() {}

    var_t::var_t(const value_t& value)
      : value_(value) {}

    var_t::var_t(value_t&& value)
      : value_(std::move(value)) {}

    const value_t& var_t::operator*() const {
      return value_;
    }

    const value_t* var_t::operator->() const {
      return &value_;
    }

    ref_t::ref_t()
      : value_(std::make_shared<value_t>()) {}

    ref_t::ref_t(const value_t& value)
      : value_(std::make_shared<value_t>(value)) {}

    ref_t::ref_t(value_t&& value)
      : value_(std::make_shared<value_t>(std::move(value))) {}

    value_t& ref_t::operator*() const {
      return *value_;
    }

    value_t* ref_t::operator->() const {
      return value_.get();
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

    const value_t& table_t::getmetatable() const {
      return metatable_;
    }

    void table_t::setmetatable(const value_t& metatable) {
      metatable_ = metatable;
    }

    thunk_t::~thunk_t() {}

    function_t::~function_t() {}
  }
}
