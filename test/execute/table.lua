-- Copyright (C) 2018 Tomoyuki Fujimori <moyu@dromozoa.com>
--
-- This file is part of dromozoa-compiler.
--
-- dromozoa-compiler is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- dromozoa-compiler is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with dromozoa-compiler.  If not, see <http://www.gnu.org/licenses/>.

local print = print

local t = {}
print(type(t))
print(t[1], t[2])
t[1] = 42
print(t[1], t[2])
t[2] = 69
print(t[1], t[2])
t[1], t[2] = t[2], t[1]
print(t[1], t[2])
print(#t)

t["foo"] = "qux"
t.bar = true
print(t.foo, t["bar"])
print(#t)

local t = {
  ["foo"] = 42;
  bar = false;
}
print(t.foo, t["bar"])
print(#t)

local t = {
  1, 2, 3;
  foo = true;
  4, 5, 6;
  bar = true;
  7, 8, 9;
}
print(t.foo, t.bar, t[1], t[9], t[10])
print(#t)

local t = {
  [1] = 17;
  42, 666;
  [1] = 69;
}
print(t[1], t[2], t[3])
print(#t)

local f = function ()
  return 1, 2, 3, 4
end

local t = {
  foo = f();
  f();
  f();
}
print(t.foo, t[1], t[2], t[3], t[4], t[5], t[6])
print(#t)
