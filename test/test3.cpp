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

void check_regexp_integer(const std::string& s) {
  using namespace dromozoa::runtime;
  std::cout
      << regexp_integer(s)
      << " [["
      << s
      << "]]"
      << "\n";
}

int main(int, char*[]) {
  using namespace dromozoa::runtime;

  check_regexp_integer("42");
  check_regexp_integer(" 42");
  check_regexp_integer(" 42 ");
  check_regexp_integer(" 42 42");
  check_regexp_integer(" 42 42 ");
  check_regexp_integer("34e1");
  check_regexp_integer("foo");
  check_regexp_integer(" foo");
  check_regexp_integer(" foo ");
  check_regexp_integer("42foo");
  check_regexp_integer("0042");
  check_regexp_integer("+0042");
  check_regexp_integer("++0042");
  check_regexp_integer("-0042");
  check_regexp_integer("0x42");
  check_regexp_integer("+0x42");
  check_regexp_integer("-0x42");
  check_regexp_integer("--0x42");
  check_regexp_integer("+");
  check_regexp_integer("0X");

  return 0;
}
