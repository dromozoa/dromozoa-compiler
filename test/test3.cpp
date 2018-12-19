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

  std::shared_ptr<thunk_t> F1(continuation_t k, std::shared_ptr<thread_t> t, array_t args);
  std::shared_ptr<thunk_t> F2(continuation_t k, std::shared_ptr<thread_t> t, array_t args);
  std::shared_ptr<thunk_t> F3(continuation_t k, std::shared_ptr<thread_t> t, array_t args);

  class F : public function_t {
  public:
    std::shared_ptr<thunk_t> operator()(continuation_t k, std::shared_ptr<thread_t> t, array_t args) {
      return make_thunk([=]() {
        return F1(k, t, args);
      });
    }
  };

  std::shared_ptr<thunk_t> F1(continuation_t k, std::shared_ptr<thread_t> t, array_t args) {
    std::cout << "foo\n";
    return make_thunk([=]() {
      return F2(k, t, args);
    });
  }

  std::shared_ptr<thunk_t> F2(continuation_t k, std::shared_ptr<thread_t> t, array_t args) {
    std::cout << "bar\n";
    return make_thunk([=]() {
      return F3(k, t, args);
    });
  }

  std::shared_ptr<thunk_t> F3(continuation_t k, std::shared_ptr<thread_t> t, array_t args) {
    std::cout << "bar\n";
    return make_thunk([=]() {
      return k(t, args);
    });
  }

  std::shared_ptr<thunk_t> f(int v) {
    std::cout << "f " << v << "\n";
    if (v == 0) {
      return nullptr;
    } else {
      return make_thunk([=]() -> std::shared_ptr<thunk_t> {
        return f(v - 1);
      });
    }
  }
}

int main(int, char*[]) {
  using namespace dromozoa::runtime;

  value_t f(std::make_shared<F>());
  auto t = (*f.checkfunction())([](std::shared_ptr<thread_t>, array_t) -> std::shared_ptr<thunk_t> {
    std::cout << "done\n";
    return nullptr;
  }, nullptr, array_t());

  while (true) {
    std::cout << "trampoline " << t << "\n";
    if (t) {
      t = (*t)();
    } else {
      break;
    }
  }

  using let_t = var_t;

  let_t x = { 42 };
  let_t y = x;
  std::cout << x->checknumber() << "\n";
  std::cout << y->checknumber() << "\n";
  *x = 69;
  std::cout << x->checknumber() << "\n";
  std::cout << y->checknumber() << "\n";

  // value_t f(std::make_shared<F>());
  // value_t g(std::make_shared<G>());

  // std::function<void()> r = (*f.checkfunction())([=](std::shared_ptr<thread_t> t, array_t args) {
  //   (*g.checkfunction())([=](std::shared_ptr<thread_t> t, array_t args) {
  //   }, nullptr, array_t());
  // }, nullptr, array_t());

  return 0;
}
