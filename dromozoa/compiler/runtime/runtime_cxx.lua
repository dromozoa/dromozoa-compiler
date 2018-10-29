return [[
#ifndef DROMOZOA_COMPILER_RUNTIME_CXX_HPP
#define DROMOZOA_COMPILER_RUNTIME_CXX_HPP

#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <functional>
#include <initializer_list>
#include <iomanip>
#include <iostream>
#include <map>
#include <memory>
#include <sstream>
#include <stdexcept>
#include <string>
#include <tuple>
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

    class error_t : public std::runtime_error {
    public:
      error_t(const char* message)
        : std::runtime_error(message) {}
    };

    class value_t;
    using array_t = std::vector<value_t>;
    using array_ptr = std::shared_ptr<array_t>;
    using upvalues_t = std::vector<std::tuple<array_ptr, std::size_t>>;
    using upvalues_ptr = std::shared_ptr<upvalues_t>;
    using string_t = std::string;
    using string_ptr = std::shared_ptr<string_t>;
    class table_t;
    using table_ptr = std::shared_ptr<table_t>;
    class function_t;
    using function_ptr = std::shared_ptr<function_t>;

    const value_t& nil() noexcept;

    array_ptr newarray(std::initializer_list<value_t> values, array_ptr array = nullptr);
    array_ptr newarray2(const value_t& value, array_ptr array);

    inline const value_t& get(array_ptr array, std::size_t index) noexcept {
      if (array && index < array->size()) {
        return (*array)[index];
      } else {
        return nil();
      }
    }

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
      function_t(std::size_t argc, bool vararg, T&& closure)
        : argc_(argc), vararg_(vararg), closure_(std::forward<T>(closure)) {}
      array_ptr call(array_ptr array) const;
    private:
      std::size_t argc_;
      bool vararg_;
      closure_t closure_;
    };

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

      ~value_t() noexcept {
        destruct();
      }

      friend value_t boolean(bool boolean);
      friend value_t number(double number);
      friend value_t string(const char* data, std::size_t size);
      friend value_t string(const std::string& data);
      friend value_t table();
      template <class T>
      friend value_t function(std::size_t argc, bool vararg, T&& closure);

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

      const value_t& getmetafield(const char* event) const noexcept {
        if (!is_table()) {
          return nil();
        }
        return table_->getmetafield(event);
      }

      table_ptr getmetatable() const noexcept {
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

      array_ptr call(array_ptr array) const {
        if (is_function()) {
          return function_->call(array);
        }
        const auto& field = getmetafield("__call");
        if (!field.is_function()) {
          throw error_t("attempt to call a non-function value");
        }
        return field.function_->call(newarray2(field, array));
      }

      void call0(array_ptr array) const {
        call(array);
      }

      value_t call1(array_ptr array = nullptr) const {
        return get(call(array), 0);
      }

      value_t gettable(const value_t& index) const {
        if (!is_table()) {
          throw error_t("table expected");
        }
        const auto i = table_->map_.find(index);
        if (i != table_->map_.end()) {
          return i->second;
        }
        const auto& field = getmetafield("__index");
        if (!field.is_nil()) {
          if (field.is_function()) {
            return field.call1(newarray({ field, *this, index }));
          } else {
            return field.gettable(index);
          }
        }
        return nil();
      }

      void settable(const value_t& index, const value_t& value) const {
        if (!is_table()) {
          throw error_t("table expected");
        }
        const auto i = table_->map_.find(index);
        if (i == table_->map_.end()) {
          const auto& field = getmetafield("__newindex");
          if (!field.is_nil()) {
            if (field.is_function()) {
              field.call0(newarray({ field, *this, index, value }));
              return;
            } else {
              field.settable(index, value);
              return;
            }
          }
        }
        if (value.is_nil()) {
          table_->map_.erase(index);
        } else {
          table_->map_[index] = value;
        }
      }

      void setlist(double index, const value_t& value) const;
      void setlist(double index, array_ptr array) const;

      std::string type() const {
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
        throw error_t("???");
      }

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
              const auto& field = getmetafield("__tostring");
              if (!field.is_nil()) {
                return field.call1(newarray({ *this })).tostring();
              }
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
        throw error_t("!!!");
      }

      double tonumber() const {
        if (is_number()) {
          return number_;
        }
        throw error_t("number expected");
      }

      std::int64_t tointeger() const {
        return tonumber();
      }

      value_t len() const;

      bool lt(const value_t& that) const {
        if (is_number() && that.is_number()) {
          return number_ < that.number_;
        } else if (is_string() && that.is_string()) {
          return string_ < that.string_;
        }
        throw error_t("attempt to compare...");
      }

      bool le(const value_t& that) const {
        if (is_number() && that.is_number()) {
          return number_ <= that.number_;
        } else if (is_string() && that.is_string()) {
          return string_ <= that.string_;
        }
        throw error_t("attempt to compare...");
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
      union {
        bool boolean_;
        double number_;
        string_ptr string_;
        table_ptr table_;
        function_ptr function_;
      };
    };

    inline value_t boolean(bool boolean) {
      value_t self;
      self.type_ = type_t::boolean;
      self.boolean_ = boolean;
      return self;
    }

    inline value_t number(double number) {
        value_t self;
        self.type_ = type_t::number;
        self.number_ = number;
      return self;
    }

    inline value_t string(const char* data, std::size_t size) {
      value_t self;
      self.type_ = type_t::string;
      new (&self.string_) string_ptr(std::make_shared<string_t>(data, size));
      return self;
    }

    inline value_t string(const std::string& data) {
      value_t self;
      self.type_ = type_t::string;
      new (&self.string_) string_ptr(std::make_shared<string_t>(data));
      return self;
    }

    inline value_t table() {
      value_t self;
      self.type_ = type_t::table;
      new (&self.table_) table_ptr(std::make_shared<table_t>());
      return self;
    }

    template <class T>
    inline value_t function(std::size_t argc, bool vararg, T&& closure) {
      value_t self;
      self.type_ = type_t::function;
      new (&self.function_) function_ptr(std::make_shared<function_t>(argc, vararg, std::forward<T>(closure)));
      return self;
    }

    inline const value_t& nil() noexcept {
      static const value_t self;
      return self;
    }

    inline const value_t& false_() noexcept {
      static const value_t self = boolean(false);
      return self;
    }

    inline const value_t& true_() noexcept {
      static const value_t self = boolean(true);
      return self;
    }

    inline array_ptr newarray(std::initializer_list<value_t> values, array_ptr array) {
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

    inline array_ptr newarray2(const value_t& value, array_ptr array) {
      array_ptr result = std::make_shared<array_t>();
      result->push_back(value);
      if (array) {
        for (const auto& value : *array) {
          result->push_back(value);
        }
      }
      return result;
    }

    inline const value_t& table_t::getmetafield(const char* event) const noexcept {
      if (metatable_) {
        const auto i = metatable_->map_.find(string(event));
        if (i != metatable_->map_.end()) {
          return i->second;
        }
      }
      return nil();
    }

    inline array_ptr function_t::call(array_ptr array) const {
      array_ptr A;
      array_ptr V;
      std::size_t i = 0;
      if (argc_) {
        A = std::make_shared<array_t>(argc_);
        for (; i < argc_; ++i) {
          (*A)[i] = get(array, i);
        }
      }
      if (vararg_) {
        V = std::make_shared<array_t>();
        for (; i < array->size(); ++i) {
          V->push_back(get(array, i));
        }
      }
      return closure_(A, V);
    }

    void value_t::setlist(double index, const value_t& value) const {
      if (!is_table()) {
        throw error_t("table expected");
      }
      // not care metafield because setlist is used from tableconstructor
      if (value.is_nil()) {
        table_->map_.erase(number(index));
      } else {
        table_->map_[number(index)] = value;
      }
    }

    void value_t::setlist(double index, array_ptr array) const {
      if (!is_table()) {
        throw error_t("table expected");
      }
      // not care metafield because setlist is used from tableconstructor
      for (const auto& value : *array) {
        if (value.is_nil()) {
          table_->map_.erase(number(index));
        } else {
          table_->map_[number(index)] = value;
        }
        ++index;
      }
    }

    value_t value_t::len() const {
      if (!is_table()) {
        throw error_t("table expected");
      }
      for (double i = 1; ; ++i) {
        if (gettable(number(i)).is_nil()) {
          return number(i - 1);
        }
      }
    }

    inline value_t open_env() {
      value_t env = table();

      env.settable(string("_G"), env);
      env.settable(string("_VERSION"), string("Lua 5.3"));

      env.settable(string("tonumber"), function(1, false, [](array_ptr A, array_ptr) -> array_ptr {
        return newarray({ number(get(A, 0).tonumber()) });
      }));

      env.settable(string("tostring"), function(1, false, [](array_ptr A, array_ptr) -> array_ptr {
        return newarray({ string(get(A, 0).tostring()) });
      }));

      env.settable(string("print"), function(0, true, [](array_ptr, array_ptr V) -> array_ptr {
        std::size_t i = 0;
        for (const auto& value : *V) {
          if (i > 0) {
            std::cout << "\t";
          }
          std::cout << value.tostring();
          ++i;
        }
        std::cout << "\n";
        return nullptr;
      }));

      env.settable(string("type"), function(1, false, [](array_ptr A, array_ptr) -> array_ptr {
        return newarray({ string(get(A, 0).type()) });
      }));

      return env;
    }
  }
}

#endif
]]
