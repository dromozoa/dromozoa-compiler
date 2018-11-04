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

#include "runtime.hpp"

#include <cmath>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <utility>

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
            throw std::logic_error("unreachable code");
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
            throw std::logic_error("unreachable code");
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
            throw std::logic_error("unreachable code");
        }
      }

      struct noop_t : function_t {
        virtual array_t operator()(array_t) {
          return {};
        }
      };

      bool is_hexint(const std::string& s) {
        auto i = s.find("0x");
        if (i == std::string::npos) {
          i = s.find("0X");
          if (i == std::string::npos) {
            return false;
          }
        }
        if (i == s.find_first_not_of(" \f\r\n\t\v+-")) {
          return s.find_first_not_of(" \f\r\n\t\v0123456789ABCDEFabcdef", i + 2) == std::string::npos;
        }
        return false;
      }

      std::size_t range_i(std::int64_t i, std::size_t size) {
        if (i < 0) {
          i += size;
          if (i < 0) {
            return 0;
          } else {
            return i;
          }
        } else if (i > 0) {
          return i - 1;
        } else {
          return 0;
        }
      }

      std::size_t range_j(std::int64_t j, std::size_t size) {
        if (j < 0) {
          j += size + 1;
          if (j < 0) {
            return 0;
          } else {
            return j;
          }
        } else if (j > static_cast<std::int64_t>(size)) {
          return size;
        } else {
          return j;
        }
      }

      void open_base(const value_t& env) {
        const value_t ipairs_iterator = [](value_t table, value_t index) -> array_t {
          index = index.checkinteger() + 1;
          const auto& value = gettable(table, index);
          if (value.is_nil()) {
            return {};
          } else {
            return { index, value };
          }
        };

        settable(env, "_G", env);

        settable(env, "_VERSION", "Lua 5.3");

        settable(env, "assert", [](array_t args) -> array_t {
          const auto& value = args[0];
          if (value.toboolean()) {
            return args;
          } else {
            if (args.size > 1) {
              throw args[1];
            } else {
              throw value_t("assertion failed!");
            }
          }
        });

        settable(env, "error", [](value_t message) {
          throw message;
        });

        settable(env, "ipairs", [=](value_t table) -> array_t {
          return { ipairs_iterator, table, 0 };
        });


        settable(env, "pcall", [](value_t f, array_t args) -> array_t {
          try {
            array_t result = call(f, args);
            return array_t(true, result);
          } catch (const value_t& e) {
            return { false, e };
          }
        });

        settable(env, "print", [](array_t args) {
          for (std::size_t i = 0; i < args.size; ++i) {
            if (i > 0) {
              std::cout << "\t";
            }
            std::cout << tostring(args[i]);
          }
          std::cout << "\n";
        });

        settable(env, "select", [](value_t index, array_t args) -> array_t {
          if (eq(index, "#")) {
            return { args.size };
          }
          return args.sub(range_i(index.checkinteger(), args.size));
        });

        settable(env, "getmetatable", [](value_t object) -> value_t {
          return getmetatable(object);
        });

        settable(env, "setmetatable", [](value_t table, value_t metatable) -> value_t {
          return setmetatable(table, metatable);
        });

        settable(env, "type", [](value_t v) -> value_t {
          return type(v);
        });
      }

      void open_string(const value_t& env, const value_t& string_metatable) {
        value_t module = type_t::table;

        settable(module, "byte", [](value_t s, value_t i, value_t j) -> array_t {
          const auto& string = s.checkstring();
          const auto index = i.optinteger(1);
          const auto min = range_i(index, string.size());
          const auto max = range_j(j.optinteger(index), string.size());
          if (min < max) {
            array_t result(max - min);
            for (std::size_t i = min; i < max; ++i) {
              result[i - min] = static_cast<std::uint8_t>(string[i]);
            }
            return result;
          } else {
            return {};
          }
        });

        settable(module, "char", [](array_t args) -> value_t {
          std::string result;
          for (std::size_t i = 0; i < args.size; ++i) {
            const auto v = args[i].checkinteger();
            if (0x00 <= v && v <= 0xFF) {
              result += static_cast<char>(v);
            } else {
              throw value_t("out of range");
            }
          }
          return result;
        });

        settable(module, "len", [](value_t s) -> value_t {
          return s.checkstring().size();
        });

        settable(module, "sub", [](value_t s, value_t i, value_t j) -> value_t {
          const auto& string = s.checkstring();
          const auto min = range_i(i.optinteger(1), string.size());
          const auto max = range_j(j.optinteger(string.size()), string.size());
          if (min < max) {
            return string.substr(min, max - min);
          } else {
            return "";
          }
        });

        settable(env, "string", module);
        settable(string_metatable, "__index", module);
      }

      value_t open(const value_t& string_metatable) {
        value_t env = type_t::table;
        open_base(env);
        open_string(env, string_metatable);
        return env;
      }
    }

    value_t NIL = type_t::nil;
    value_t FALSE = false;
    value_t TRUE = true;
    value_t string_metatable = type_t::table;
    value_t env = open(string_metatable);

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
        throw std::logic_error("cannot assign to constant value");
      }
      destruct(*this);
      copy_construct(*this, that);
      return *this;
    }

    value_t& value_t::operator=(value_t&& that) {
      if (mode == mode_t::constant) {
        throw std::logic_error("cannot assign to constant value");
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
          new (&function) function_ptr(std::make_shared<noop_t>());
          break;
        default:
          throw std::logic_error("unreachable code");
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

    value_t::value_t(function_ptr function)
      : mode(mode_t::constant),
        type(type_t::function) {
      new (&this->function) function_ptr(function);
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
          return *string < *that.string;
        case type_t::table:
          return table < that.table;
        case type_t::function:
          return function < that.function;
        default:
          throw std::logic_error("unreachable code");
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

    bool value_t::toboolean() const {
      if (is_nil()) {
        return false;
      } else if (is_boolean()) {
        return boolean;
      }
      return true;
    }

    double value_t::checknumber() const {
      if (is_number()) {
        return number;
      } else if (is_string()) {
        auto n = string->find_last_not_of(" \f\n\r\t\v");
        if (n != std::string::npos) {
          ++n;
          try {
            std::size_t i = 0;
            const std::int64_t integer = std::stoll(*string, &i, 10);
            if (i == n) {
              return integer;
            }
          } catch (const std::exception&) {}
          if (is_hexint(*string)) {
            try {
              std::size_t i = 0;
              const std::int64_t integer = std::stoll(*string, &i, 16);
              if (i == n) {
                return integer;
              }
            } catch (const std::exception&) {}
          }
          try {
            std::size_t i = 0;
            const double number = std::stod(*string, &i);
            if (i == n) {
              return number;
            }
          } catch (const std::exception&) {}
        }
      }
      throw value_t("number expected, got " + dromozoa::runtime::type(*this));
    }

    std::int64_t value_t::checkinteger() const {
      if (is_number()) {
        if (std::isfinite(number) && number == std::floor(number)) {
          return number;
        } else {
          throw value_t("number has no integer representation");
        }
      } else if (is_string()) {
        auto n = string->find_last_not_of(" \f\n\r\t\v");
        if (n != std::string::npos) {
          ++n;
          try {
            std::size_t i = 0;
            const std::int64_t integer = std::stoll(*string, &i, 10);
            if (i == n) {
              return integer;
            }
          } catch (const std::exception&) {}
          if (is_hexint(*string)) {
            try {
              std::size_t i = 0;
              const std::int64_t integer = std::stoll(*string, &i, 16);
              if (i == n) {
                return integer;
              }
            } catch (const std::exception&) {}
          }
          try {
            std::size_t i = 0;
            const double number = std::stod(*string, &i);
            if (i == n) {
              if (std::isfinite(number) && number == std::floor(number)) {
                return number;
              } else {
                throw value_t("number has no integer representation");
              }
            }
          } catch (const std::exception&) {}
        }
      }
      throw value_t("integer expected, got " + dromozoa::runtime::type(*this));
    }

    std::string value_t::checkstring() const {
      if (is_string()) {
        return *string;
      } else if (is_number()) {
        std::ostringstream out;
        out << std::setprecision(17) << number;
        return out.str();
      }
      throw value_t("string expected, got " + dromozoa::runtime::type(*this));
    }

    table_ptr value_t::checktable() const {
      if (is_table()) {
        return table;
      }
      throw value_t("table expected, got " + dromozoa::runtime::type(*this));
    }

    std::int64_t value_t::optinteger(std::int64_t d) const {
      if (is_nil()) {
        return d;
      } else {
        return checkinteger();
      }
    }

    const value_t& table_t::get(const value_t& index) const {
      const auto i = map.find(index);
      if (i == map.end()) {
        return NIL;
      } else {
        return i->second;
      }
    }

    void table_t::set(const value_t& index, const value_t& value) {
      if (index.is_nil()) {
        throw value_t("table index is nil");
      }
      if (value.is_nil()) {
        map.erase(index);
      } else {
        map[index] = value;
      }
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

    array_t::array_t(std::initializer_list<value_t> source, array_t array)
      : array_t() {
      const auto n = source.size() + array.size;
      if (n > 0) {
        data = std::shared_ptr<value_t>(new value_t[n], std::default_delete<value_t[]>());
        size = n;
        auto* ptr = data.get();
        for (const auto& value : source) {
          *ptr++ = value;
        }
        for (std::size_t i = 0; i < array.size; ++i) {
          *ptr++ = array.data.get()[i];
        }
      }
    }

    array_t::array_t(const value_t& value, array_t array) {
      const auto n = array.size + 1;
      data = std::shared_ptr<value_t>(new value_t[n], std::default_delete<value_t[]>());
      size = n;
      auto* ptr = data.get();
      *ptr++ = value;
      for (std::size_t i = 0; i < array.size; ++i) {
        *ptr++ = array.data.get()[i];
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

    upvalue_t::upvalue_t()
      : index() {}

    upvalue_t::upvalue_t(array_t array, std::size_t index)
      : array(array),
        index(index) {}

    value_t& upvalue_t::operator*() const {
      return array[index];
    }

    uparray_t::uparray_t()
      : size() {}

    uparray_t::uparray_t(std::initializer_list<upvalue_t> source)
      : uparray_t() {
      const auto n = source.size();
      if (n > 0) {
        data = std::shared_ptr<upvalue_t>(new upvalue_t[n], std::default_delete<upvalue_t[]>());
        size = n;
        auto* ptr = data.get();
        for (const auto& upvalue : source) {
          *ptr++ = upvalue;
        }
      }
    }

    upvalue_t& uparray_t::operator[](std::size_t i) const {
      if (i < size) {
        return data.get()[i];
      } else {
        throw std::out_of_range("invalid uparray index");
      }
    }

    const value_t& rawget(const value_t& table, const value_t& index) {
      return table.checktable()->get(index);
    }

    const value_t& rawset(const value_t& table, const value_t& index, const value_t& value) {
      table.checktable()->set(index, value);
      return table;
    }

    const value_t& getmetafield(const value_t& object, const value_t& event) {
      value_t metatable;
      if (object.is_string()) {
        metatable = string_metatable;
      } else if (object.is_table()) {
        metatable = object.table->metatable;
      }
      if (metatable.is_table()) {
        return rawget(metatable, event);
      } else {
        return NIL;
      }
    }

    const value_t& getmetatable(const value_t& object) {
      if (object.is_string()) {
        return string_metatable;
      } else if (object.is_table()) {
        const auto& metatable = object.table->metatable;
        if (metatable.is_table()) {
          const auto& protected_metatable = rawget(metatable, "__metatable");
          if (!protected_metatable.is_nil()) {
            return protected_metatable;
          }
        }
        return metatable;
      } else {
        return NIL;
      }
    }

    const value_t& setmetatable(const value_t& table, const value_t& metatable) {
      if (!metatable.is_nil() && !metatable.is_table()) {
        throw value_t("nil or table expected");
      }
      if (!getmetafield(table, "__metatable").is_nil()) {
        throw value_t("cannot change a protected metatable");
      }
      table.checktable()->metatable = metatable;
      return table;
    }

    value_t gettable(const value_t& table, const value_t& index) {
      if (table.is_string()) {
        const auto& field = getmetafield(table, "__index");
        if (!field.is_nil()) {
          if (field.is_function()) {
            return call1(field, { table, index });
          } else {
            return gettable(field, index);
          }
        }
      }
      const auto& result = rawget(table, index);
      if (result.is_nil()) {
        const auto& field = getmetafield(table, "__index");
        if (!field.is_nil()) {
          if (field.is_function()) {
            return call1(field, { table, index });
          } else {
            return gettable(field, index);
          }
        }
      }
      return result;
    }

    void settable(const value_t& table, const value_t& index, const value_t& value) {
      const auto& result = rawget(table, index);
      if (result.is_nil()) {
        const auto& field = getmetafield(table, "__newindex");
        if (!field.is_nil()) {
          if (field.is_function()) {
            return call0(field, { table, index, value });
          } else {
            return settable(field, index, value);
          }
        }
      }
      rawset(table, index, value);
    }

    void setlist(const value_t& table, std::size_t index, const value_t& value) {
      rawset(table, index, value);
    }

    void setlist(const value_t& table, std::size_t index, const array_t& array) {
      for (size_t i = 0; i < array.size; ++i) {
        rawset(table, index++, array[i]);
      }
    }

    array_t call(const value_t& f, const array_t& args) {
      if (f.is_function()) {
        return (*f.function)(args);
      } else {
        const auto& field = getmetafield(f, "__call");
        if (field.is_function()) {
          return (*field.function)(array_t(f, args));
        } else {
          throw value_t("attempt to call a " + type(f) + " value");
        }
      }
    }

    value_t call1(const value_t& f, const array_t& args) {
      return call(f, args)[0];
    }

    void call0(const value_t& f, const array_t& args) {
      call(f, args);
    }

    std::string type(const value_t& v) {
      switch (v.type) {
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
        default:
          throw std::logic_error("unreachable code");
      }
    }

    std::string tostring(const value_t& v) {
      switch (v.type) {
        case type_t::nil:
          return "nil";
        case type_t::boolean:
          if (v.boolean) {
            return "true";
          } else {
            return "false";
          }
        case type_t::number:
          {
            std::ostringstream out;
            out << std::setprecision(17) << v.number;
            return out.str();
          }
        case type_t::string:
          return *v.string;
        case type_t::table:
          {
            const auto& field = getmetafield(v, "__tostring");
            if (!field.is_nil()) {
              return call1(field, { v }).checkstring();
            } else {
              std::ostringstream out;
              out << "table: " << v.table.get();
              return out.str();
            }
          }
        case type_t::function:
          {
            std::ostringstream out;
            out << "function: " << v.function.get();
            return out.str();
          }
        default:
          throw std::logic_error("unreachable code");
      }
    }

    std::int64_t len(const value_t& v) {
      if (v.is_string()) {
        return v.string->size();
      } else if (v.is_table()) {
        const auto& field = getmetafield(v, "__len");
        if (!field.is_nil()) {
          return call1(field, { v }).checkinteger();
        }
        for (std::int64_t i = 1; ; ++i) {
          if (gettable(v, i).is_nil()) {
            return i - 1;
          }
        }
      }
      throw value_t("attempt to get length of a " + type(v) + " value");
    }

    bool eq(const value_t& self, const value_t& that) {
      if (self.type != that.type) {
        return false;
      }
      switch (self.type) {
        case type_t::nil:
          return true;
        case type_t::boolean:
          return self.boolean == that.boolean;
        case type_t::number:
          return self.number == that.number;
        case type_t::string:
          return *self.string == *that.string;
        case type_t::table:
          if (self.table == that.table) {
            return true;
          } else {
            auto field = getmetafield(self, "__eq");
            if (field.is_nil()) {
              field = getmetafield(that, "__eq");
            }
            if (!field.is_nil()) {
              return call1(field, { self, that }).toboolean();
            }
            return false;
          }
        case type_t::function:
          return self.function == that.function;
        default:
          throw std::logic_error("unreachable code");
      }
    }

    bool lt(const value_t& self, const value_t& that) {
      if (self.is_number() && that.is_number()) {
        return self.number < that.number;
      } else if (self.is_string() && that.is_string()) {
        return *self.string < *that.string;
      } else {
        auto field = getmetafield(self, "__lt");
        if (field.is_nil()) {
          field = getmetafield(that, "__lt");
        }
        if (!field.is_nil()) {
          return call1(field, { self, that }).toboolean();
        }
      }
      throw value_t("attempt to compare " + type(self) + " with " + type(that));
    }

    bool le(const value_t& self, const value_t& that) {
      if (self.is_number() && that.is_number()) {
        return self.number <= that.number;
      } else if (self.is_string() && that.is_string()) {
        return *self.string <= *that.string;
      } else {
        auto field = getmetafield(self, "__le");
        if (field.is_nil()) {
          field = getmetafield(that, "__le");
        }
        if (!field.is_nil()) {
          return call1(field, { self, that }).toboolean();
        }
        field = getmetafield(that, "__lt");
        if (field.is_nil()) {
          field = getmetafield(self, "__lt");
        }
        if (!field.is_nil()) {
          return !call1(field, { that, self }).toboolean();
        }
      }
      throw value_t("attempt to compare " + type(self) + " with " + type(that));
    }
  }
}
