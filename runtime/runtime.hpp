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
#include <map>
#include <memory>
#include <string>
#include <type_traits>
#include <utility>

namespace dromozoa {
  namespace runtime {
    template <bool T_condition, class T = void>
    using enable_if_t = typename std::enable_if<T_condition, T>::type;

    enum class type_t : std::uint8_t {
      nil,
      boolean,
      number,
      string,
      table,
      function,
      thread,
    };

    class array_t;
    class table_t;
    class function_t;
    class thread_t;

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
      value_t(std::shared_ptr<thread_t>);

      template <class T>
      value_t(T value, enable_if_t<std::is_integral<T>::value>* = 0)
        : value_t(static_cast<double>(value)) {}

      bool operator<(const value_t&) const;

      std::string type() const;
      bool isnil() const;
      bool isboolean() const;
      bool isnumber() const;
      bool isstring() const;
      bool istable() const;
      bool isfunction() const;
      bool isthread() const;

      bool toboolean() const;
      bool tonumber(double& result) const;

      double checknumber() const;
      std::int64_t checkinteger() const;
      std::string checkstring() const;
      std::shared_ptr<table_t> checktable() const;
      std::shared_ptr<function_t> checkfunction() const;
      std::shared_ptr<thread_t> checkthread() const;

      std::int64_t optinteger(std::int64_t) const;

      bool rawequal(const value_t&) const;
      std::int64_t rawlen() const;
      const value_t& rawget(const value_t&) const;
      void rawset(const value_t&, const value_t&) const;
      void rawset(const value_t&, const array_t&) const;

    private:
      type_t type_;
      union {
        bool boolean_;
        double number_;
        std::shared_ptr<std::string> string_;
        std::shared_ptr<table_t> table_;
        std::shared_ptr<function_t> function_;
        std::shared_ptr<thread_t> thread_;
      };
    };

    extern value_t NIL;
    extern value_t FALSE;
    extern value_t TRUE;

    class var_t {
    public:
      var_t();
      var_t(const value_t&);
      var_t(value_t&&);
      value_t& operator*();
      value_t* operator->();
    private:
      value_t value_;
    };

    class ref_t {
    public:
      ref_t();
      ref_t(const value_t&);
      ref_t(value_t&&);
      value_t& operator*() const;
      value_t* operator->() const;
    private:
      std::shared_ptr<value_t> value_;
    };

    class array_t {
    public:
      array_t();
      array_t(std::size_t);
      value_t& operator[](std::size_t) const;
      std::size_t size() const;
      array_t sub(std::size_t) const;
    private:
      std::shared_ptr<value_t> data_;
      std::size_t size_;
    };

    class table_t {
    public:
      const value_t& get(const value_t&) const;
      void set(const value_t&, const value_t&);
      const value_t& getmetatable() const;
      void setmetatable(const value_t&);
    private:
      std::map<value_t, value_t> map_;
      value_t metatable_;
    };

    class thunk_t {
    public:
      virtual ~thunk_t();
      virtual std::shared_ptr<thunk_t> operator()() = 0;
    };

    template <class T>
    class thunk_impl : public thunk_t {
    public:
      thunk_impl(const T& function)
        : function_(function) {}

      thunk_impl(T&& function)
        : function_(std::move(function)) {}

      virtual std::shared_ptr<thunk_t> operator()() {
        return function_();
      }

    private:
      T function_;
    };

    template <typename T>
    inline std::shared_ptr<thunk_t> make_thunk(T&& function) {
      return std::make_shared<thunk_impl<T>>(std::forward<T>(function));
    }

    using continuation_t = std::function<std::shared_ptr<thunk_t>(std::shared_ptr<thread_t>, array_t)>;

    class state {
    public:
    private:
      continuation_t continuation_;
      std::shared_ptr<thread_t> thread_;
    };

    class function_t {
    public:
      virtual ~function_t();
      virtual std::shared_ptr<thunk_t> operator()(continuation_t, std::shared_ptr<thread_t>, array_t) = 0;
    };

    class thread_t {
    public:
      thread_t();
    private:
      std::shared_ptr<function_t> body_;
    };

  }
}

#endif
