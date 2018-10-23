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

local n = 0
local f = function ()
  n = n + 1
  return 1, 2, 3, 4
end

local print = print
local a, b, c = f()
print(n, a, b, c)
local a, b, c = f(), 42
print(n, a, b, c)
local a, b, c = f(), f(), 42
print(n, a, b, c)
local a, b, c = 42, f()
print(n, a, b, c)
local a, b, c = 42, 42, f()
print(n, a, b, c)
local a, b, c = 42, 42, 42, f()
print(n, a, b, c)
