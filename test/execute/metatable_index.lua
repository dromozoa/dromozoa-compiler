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

local class = {
  foo = 1;
}

local metatable = {
  __index = class;
  __newindex = class;
}

local t1 = {
  bar = 2;
}

print(t1.foo, t1.bar, t1.baz)

setmetatable(t1, metatable)
local t2 = setmetatable({
  foo = 3;
  bar = 4;
}, metatable)

print(t1.foo, t1.bar, t1.baz)
print(t2.foo, t2.bar, t2.baz)

t1.baz = 5

print(t1.foo, t1.bar, t1.baz)
print(t2.foo, t2.bar, t2.baz)

function metatable:__index(k)
  print(type(self), k)
  return k
end

function metatable:__newindex(k, v)
  print(type(self), k, v)
end

print(t1.foo, t1.bar, t1.baz)
print(t2.foo, t2.bar, t2.baz)

t1.baz = 6

print(t1.foo, t1.bar, t1.baz)
print(t2.foo, t2.bar, t2.baz)
