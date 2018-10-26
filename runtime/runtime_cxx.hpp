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
#include <functional>
#include <initializer_list>
#include <iostream>
#include <map>
#include <memory>
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

    class value_t;

    using array_t = std::vector<value_t>;
    using array_ptr = std::shared_ptr<array_t>;

    class tuple_t {
    public:
      tuple_t(std::initializer_list<value_t> values, array_ptr extra = nullptr)
        : values_(values), extra_(extra) {}

      std::size_t size() const {
        if (extra_) {
          return values_.size() + extra_->size();
        } else {
          return values_.size();
        }
      }

      const value_t& operator[](std::size_t index) const;

      array_ptr make_array() const;

    private:
      std::initializer_list<value_t> values_;
      array_ptr extra_;
    };

    class function_t {
    public:
      using closure_t = std::function<tuple_t(array_ptr, array_ptr)>;

      template <class T>
      function_t(std::size_t argc, bool vararg, const T& closure)
        : argc_(argc), vararg_(vararg), closure_(closure) {}

      template <class T>
      function_t(std::size_t argc, bool vararg, T&& closure)
        : argc_(argc), vararg_(vararg), closure_(std::move(closure)) {}

      function_t(const function_t&) = delete;
      function_t(function_t&&) = delete;
      function_t& operator=(const function_t&) = delete;
      function_t& operator=(function_t&&) = delete;

      tuple_t call(std::initializer_list<value_t> values, array_ptr extra = nullptr);

    private:
      std::size_t argc_;
      bool vararg_;
      closure_t closure_;
    };

    using string_t = std::string;
    using string_ptr = std::shared_ptr<const string_t>;
    using table_t = std::map<value_t, value_t>;
    using table_ptr = std::shared_ptr<table_t>;
    using function_ptr = std::shared_ptr<const function_t>;

    class value_t {
    public:
      value_t() noexcept {
        type_ = type_t::nil;
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

      ~value_t() {
        destruct();
      }

      void swap(value_t& that) noexcept {
        std::swap(type_, that.type_);
        switch (type_) {
          case type_t::nil:
            break;
          case type_t::boolean:
            std::swap(boolean_, that.boolean_);
            break;
          case type_t::number:
            std::swap(number_, that.number_);
            break;
          case type_t::string:
            std::swap(string_, that.string_);
            break;
          case type_t::table:
            std::swap(table_, that.table_);
            break;
          case type_t::function:
            std::swap(function_, that.function_);
            break;
        }
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

      static value_t string(const char* data, std::size_t size) {
        value_t self;
        self.type_ = type_t::string;
        new (&self.string_) string_ptr(std::make_shared<const string_t>(data, size));
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
        new (&self.function_) function_ptr(std::make_shared<const function_t>(argc, vararg, closure));
        return self;
      }

      template <class T>
      static value_t function(std::size_t argc, bool vararg, T&& closure) {
        value_t self;
        self.type_ = type_t::function;
        new (&self.function_) function_ptr(std::make_shared<const function_t>(argc, vararg, std::move(closure)));
        return self;
      }

      friend std::ostream& operator<<(std::ostream& out, const value_t& self) {
        switch (self.type_) {
          case type_t::nil:
            out << "nil";
            break;
          case type_t::boolean:
            if (self.boolean_) {
              out << "true";
            } else {
              out << "false";
            }
            break;
          case type_t::number:
            out << self.number_;
            break;
          case type_t::string:
            out << *self.string_;
            break;
          case type_t::table:
            out << "table: " << self.table_.get();
            break;
          case type_t::function:
            out << "function: " << self.function_.get();
            break;
        }
        return out;
      }

      bool operator<(const value_t& rhs) {
        return type_ < rhs.type_;
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
        type_ = type_t::nil;
      }

      type_t type_;
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

    inline const value_t& tuple_t::operator[](std::size_t index) const {
      std::size_t size = values_.size();
      if (index < size) {
        return *(values_.begin() + index);
      }
      if (extra_) {
        index -= size;
        if (index < extra_->size()) {
          return (*extra_)[index];
        }
      }
      return NIL;
    }

    inline array_ptr tuple_t::make_array() const {
      array_ptr array = std::make_shared<array_t>();
      for (const value_t& value : values_) {
        array->push_back(value);
      }
      if (extra_) {
        for (const value_t& value : *extra_) {
          array->push_back(value);
        }
      }
      return array;
    }

    inline tuple_t function_t::call(std::initializer_list<value_t> values, array_ptr extra) {
      tuple_t args(values, extra);
      array_ptr A;
      array_ptr V;
      std::size_t i = 0;
      if (argc_) {
        A = std::make_shared<array_t>(argc_);
        for (; i < argc_; ++i) {
          (*A)[i] = args[i];
        }
      }
      if (vararg_) {
        V = std::make_shared<array_t>();
        for (; i < args.size(); ++i) {
          V->push_back(args[i]);
        }
      }
      return closure_(A, V);
    }
  }
}

#endif
