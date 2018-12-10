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

#include <iostream>

#include "runtime.hpp"

namespace {
  using namespace dromozoa::runtime;

  std::function<void()> F1(continuation_t k, std::shared_ptr<thread_t> t, array_t args);
  std::function<void()> F2(continuation_t k, std::shared_ptr<thread_t> t, array_t args);
  std::function<void()> F3(continuation_t k, std::shared_ptr<thread_t> t, array_t args);

  class F : public function_t {
  public:
    std::function<void()> operator()(continuation_t k, std::shared_ptr<thread_t> t, array_t args) {
      return [=]() {
        F1(k, t, args);
      };
    }
  };

  std::function<void()> F1(continuation_t k, std::shared_ptr<thread_t> t, array_t args) {
    std::cout << "foo\n";
    return [=]() {
      F2(k, t, args);
    };
  }

  std::function<void()> F2(continuation_t k, std::shared_ptr<thread_t> t, array_t args) {
    std::cout << "bar\n";
    return [=]() {
      F3(k, t, args);
    };
  }

  std::function<void()> F3(continuation_t k, std::shared_ptr<thread_t> t, array_t args) {
    std::cout << "baz\n";
    return [=]() {
      k(t, array_t());
    };
  }

  std::function<void()> G1(continuation_t k, std::shared_ptr<thread_t> t, array_t args);

  class G : public function_t {
  public:
    std::function<void()> operator()(continuation_t k, std::shared_ptr<thread_t> t, array_t args) {
      return [=]() {
        G1(k, t, args);
      };
    }
  };

  std::function<void()> G1(continuation_t k, std::shared_ptr<thread_t> t, array_t args) {
    std::cout << "qux\n";
    return [=]() {
      k(t, array_t());
    };
  }
}

int main(int, char*[]) {
  using namespace dromozoa::runtime;

  value_t f(std::make_shared<F>());
  value_t g(std::make_shared<G>());

  // std::function<void()> r = (*f.checkfunction())([=](std::shared_ptr<thread_t> t, array_t args) {
  //   (*g.checkfunction())([=](std::shared_ptr<thread_t> t, array_t args) {
  //   }, nullptr, array_t());
  // }, nullptr, array_t());

  return 0;
}
