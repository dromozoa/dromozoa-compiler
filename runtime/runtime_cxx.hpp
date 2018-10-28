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

#ifndef DROMOZOA_COMPILER_RUNTIME_CXX_HPP
#define DROMOZOA_COMPILER_RUNTIME_CXX_HPP

#include <cstddef>
#include <cstdint>
#include <cstring>
#include <array>
#include <functional>
#include <initializer_list>
#include <iomanip>
#include <iostream>
#include <map>
#include <memory>
#include <sstream>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

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

    using error_t = std::runtime_error;

    class value_t;
    using array_t = std::vector<value_t>;
    using array_ptr = std::shared_ptr<array_t>;
    using string_t = std::string;
    using string_ptr = std::shared_ptr<string_t>;
    class table_t;
    using table_ptr = std::shared_ptr<table_t>;
    class function_t;
    using function_ptr = std::shared_ptr<function_t>;

    class table_t {
      friend class value_t;
    public:
      using map_t = std::map<value_t, value_t>;
      const value_t& getmetafield(const char* event) const noexcept;
    private:
      map_t map_;
      table_ptr metatable_;
    };

    class function_t {
    public:
      using closure_t = std::function<array_ptr(array_ptr, array_ptr)>;
      template <class T>
      function_t(std::size_t argc, bool vararg, const T& closure)
        : argc_(argc), vararg_(vararg), closure_(closure) {}
      template <class T>
      function_t(std::size_t argc, bool vararg, T&& closure)
        : argc_(argc), vararg_(vararg), closure_(std::move(closure)) {}
      array_ptr call(const std::initializer_list<value_t>& values, array_ptr array = nullptr) const;
    private:
      std::size_t argc_;
      bool vararg_;
      closure_t closure_;
    };

    class value_t {
    public:
      value_t() noexcept {
        type_ = type_t::nil;
        number_ = 42;
      }

      value_t(const value_t& that) noexcept {
        construct(that);
      }

      value_t(value_t&& that) noexcept {
        construct(that);
      }

      value_t& operator=(const value_t& that) noexcept {
        destruct();
        construct(that);
        return *this;
      }

      value_t& operator=(value_t&& that) noexcept {
        destruct();
        construct(that);
        return *this;
      }

      ~value_t() noexcept {
        destruct();
      }

      bool is_nil() const noexcept {
        return type_ == type_t::nil;
      }

      bool is_boolean() const noexcept {
        return type_ == type_t::boolean;
      }

      bool is_number() const noexcept {
        return type_ == type_t::number;
      }

      bool is_string() const noexcept {
        return type_ == type_t::string;
      }

      bool is_table() const noexcept {
        return type_ == type_t::table;
      }

      bool is_function() const noexcept {
        return type_ == type_t::function;
      }

      static value_t boolean(bool boolean) {
        value_t self;
        self.type_ = type_t::boolean;
        self.boolean_ = boolean;
        return self;
      }

      static value_t number(double number) {
        value_t self;
        self.type_ = type_t::number;
        self.number_ = number;
        return self;
      }

      static value_t string(string_t&& string) {
        value_t self;
        self.type_ = type_t::string;
        new (&self.string_) string_ptr(std::make_shared<string_t>(std::move(string)));
        return self;
      }

      static value_t string(const char* data, std::size_t size) {
        value_t self;
        self.type_ = type_t::string;
        new (&self.string_) string_ptr(std::make_shared<string_t>(data, size));
        return self;
      }

      static value_t table() {
        value_t self;
        self.type_ = type_t::table;
        new (&self.table_) table_ptr(std::make_shared<table_t>());
        return self;
      }

      template <class T>
      static value_t function(std::size_t argc, bool vararg, const T& closure) {
        value_t self;
        self.type_ = type_t::function;
        new (&self.function_) function_ptr(std::make_shared<function_t>(argc, vararg, closure));
        return self;
      }

      template <class T>
      static value_t function(std::size_t argc, bool vararg, T&& closure) {
        value_t self;
        self.type_ = type_t::function;
        new (&self.function_) function_ptr(std::make_shared<function_t>(argc, vararg, std::move(closure)));
        return self;
      }

      const value_t& getmetafield(const char* event) const noexcept;

      const table_ptr getmetatable() const noexcept {
        // TODO return string module if is_string()
        if (!is_table()) {
          return nullptr;
        }
        return table_->metatable_;
      }

      void setmetatable(const value_t& metatable) {
        if (!is_table()) {
          throw error_t("table expected");
        }
        if (!metatable.is_nil() && !metatable.is_table()) {
          throw error_t("nil or table expected");
        }
        if (table_->metatable_) {
          if (!table_->metatable_->getmetafield("__metatable").is_nil()) {
            throw error_t("cannot change a protected metatable");
          }
        }
        if (metatable.is_nil()) {
          table_->metatable_ = nullptr;
        } else {
          table_->metatable_ = metatable.table_;
        }
      }

      array_ptr call(const std::initializer_list<value_t>& values, array_ptr extra = nullptr) const {
        if (is_function()) {
          return function_->call(values, extra);
        }
        // TODO test lua5.3 behavior
        const auto& field = getmetafield("__call");
        if (field.is_function()) {
          // TODO more nice interface (fixed size, no allocation)
          // return field.call({ field }, tuple_t(values, extra).make_array());
        }
        throw error_t("function expected");
      }

      void call0(const std::initializer_list<value_t>& values, array_ptr extra = nullptr) const {
        call(values, extra);
      }

      // value_t call1(const std::initializer_list<value_t>& values, array_ptr extra = nullptr) const {
      //   return (*call(values, extra))[0];
      // }

      std::string tostring() const {
        switch (type_) {
          case type_t::nil:
            return "nil";
          case type_t::boolean:
            if (boolean_) {
              return "true";
            } else {
              return "false";
            }
          case type_t::number:
            {
              std::ostringstream out;
              out << std::setprecision(17) << number_;
              return out.str();
            }
          case type_t::string:
            return *string_;
          case type_t::table:
            {
              // TODO impl __tostring
              std::ostringstream out;
              out << "table: " << table_.get();
              return out.str();
            }
          case type_t::function:
            {
              std::ostringstream out;
              out << "function: " << function_.get();
              return out.str();
            }
        }
      }

      friend std::ostream& operator<<(std::ostream& out, const value_t& self) {
        return out << self.tostring();
      }

      bool operator==(const value_t& that) const noexcept {
        if (type_ != that.type_) {
          return false;
        }
        switch (type_) {
          case type_t::nil:
            return true;
          case type_t::boolean:
            return boolean_ == that.boolean_;
          case type_t::number:
            return number_ == that.number_;
          case type_t::string:
            return *string_ == *that.string_;
          case type_t::table:
            return table_ == that.table_;
          case type_t::function:
            return function_ == that.function_;
        }
      }

      bool operator!=(const value_t& that) const noexcept {
        return !operator==(that);
      }

      bool operator<(const value_t& that) const noexcept {
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

    private:
      void construct(const value_t& that) noexcept {
        type_ = that.type_;
        switch (type_) {
          case type_t::nil:
            break;
          case type_t::boolean:
            boolean_ = that.boolean_;
            break;
          case type_t::number:
            number_ = that.number_;
            break;
          case type_t::string:
            new (&string_) string_ptr(that.string_);
            break;
          case type_t::table:
            new (&table_) table_ptr(that.table_);
            break;
          case type_t::function:
            new (&function_) function_ptr(that.function_);
            break;
        }
      }

      void construct(value_t&& that) noexcept {
        type_ = that.type_;
        that.type_ = type_t::nil;
        switch (type_) {
          case type_t::nil:
            break;
          case type_t::boolean:
            boolean_ = that.boolean_;
            break;
          case type_t::number:
            number_ = that.number_;
            break;
          case type_t::string:
            new (&string_) string_ptr(std::move(that.string_));
            break;
          case type_t::table:
            new (&table_) table_ptr(std::move(that.table_));
            break;
          case type_t::function:
            new (&function_) function_ptr(std::move(that.function_));
            break;
        }
      }

      void destruct() noexcept {
        switch (type_) {
          case type_t::nil:
            break;
          case type_t::boolean:
            break;
          case type_t::number:
            break;
          case type_t::string:
            string_.~shared_ptr();
            break;
          case type_t::table:
            table_.~shared_ptr();
            break;
          case type_t::function:
            function_.~shared_ptr();
            break;
        }
      }

      type_t type_;
      // TODO const flag
      union {
        bool boolean_;
        double number_;
        string_ptr string_;
        table_ptr table_;
        function_ptr function_;
      };
    };

    static const value_t NIL;
    static const value_t FALSE = value_t::boolean(false);
    static const value_t TRUE = value_t::boolean(true);

    inline array_ptr newarray(const std::initializer_list<value_t>& values, array_ptr array = nullptr) {
      array_ptr result = std::make_shared<array_t>();
      for (const auto& value : values) {
        result->push_back(value);
      }
      if (array) {
        for (const auto& value : *array) {
          result->push_back(value);
        }
      }
      return result;
    }

    inline const value_t& get(array_ptr array, std::size_t index) {
      if (index < array->size()) {
        return (*array)[index];
      } else {
        return NIL;
      }
    }

    inline const value_t& table_t::getmetafield(const char* event) const noexcept {
      if (metatable_) {
        const auto i = metatable_->map_.find(value_t::string(event, std::strlen(event)));
        if (i != metatable_->map_.end()) {
          return i->second;
        }
      }
      return NIL;
    }

    inline array_ptr function_t::call(const std::initializer_list<value_t>& values, array_ptr extra) const {
      const auto args = newarray(values, extra);
      array_ptr A;
      array_ptr V;
      std::size_t i = 0;
      if (argc_) {
        A = std::make_shared<array_t>(argc_);
        for (; i < argc_; ++i) {
          (*A)[i] = (*args)[i];
        }
      }
      if (vararg_) {
        V = std::make_shared<array_t>();
        for (; i < args->size(); ++i) {
          V->push_back((*args)[i]);
        }
      }
      return closure_(A, V);
    }

    inline value_t open_env() {
      value_t env = value_t::table();

      return env;
    }

    inline const value_t& value_t::getmetafield(const char* event) const noexcept {
      if (!is_table()) {
        return NIL;
      }
      return table_->getmetafield(event);
    }
  }
}

#endif
