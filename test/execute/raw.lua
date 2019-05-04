-- Copyright (C) 2018,2019 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local metaindex = {
  foo = 1;
}

local metatable = {
  __eq = function (a, b)
    return a[1] == b[1]
  end;
  __index = metaindex;
  __newindex = metaindex;
}

local t1 = setmetatable({ 42 }, metatable)
local t2 = setmetatable({ 42 }, metatable)

print(t1.foo, rawget(t1, "foo"), metaindex.foo)
t1.foo = 2
print(t1.foo, rawget(t1, "foo"), metaindex.foo)
rawset(t1, "foo", 3);
print(t1.foo, rawget(t1, "foo"), metaindex.foo)

print(t1 == t2)
print(rawequal(t1, t2))
