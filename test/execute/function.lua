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

local t = { a = { b = {} } }
local self = 42

local function f(...)
  print(1, self, ...)
end

f(1, 2, 3, 4)

function f(...)
  print(2, self, ...)
end

f(1, 2, 3, 4)

function t.f(...)
  print(3, self, ...)
end

t.f(1, 2, 3, 4)

function t.a.f(...)
  print(4, self, ...)
end

t.a.f(1, 2, 3, 4)

function t.a.b.f(...)
  print(5, self, ...)
end

t.a.b.f(1, 2, 3, 4)

function t:f(...)
  print(6, self, ...)
end

t.f(1, 2, 3, 4)

function t.a:f(...)
  print(7, self, ...)
end

t.a.f(1, 2, 3, 4)

function t.a.b:f(...)
  print(8, self, ...)
end

t.a.b.f(1, 2, 3, 4)
