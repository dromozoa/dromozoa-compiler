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

local a = 1
local a, b = 1, 2
local a, b, c = 1, 2, 3

a = a
a, b = b, a
a, b, c = c, a, b

x, y, z = nil

_ENV.X = {}
_ENV.X.Y = {}
_ENV.X.Y.Z = {}

a = {}
a[1] = {}
a[1][2] = {}
a.b = {}
a.b.c = {}
a.b = a.b
a.b.c = a.b.c

local function f1()
  return a
end

local function f2()
  return f1
end

function f3()
  return f3
end

f1().x = {}
f1().x.y = {}
f2()().x = {}
f2()().x.y = {}
