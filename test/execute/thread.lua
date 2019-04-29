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

local thread = coroutine.create(function (v)
  print("x", v)
  local v = coroutine.yield(100)
  print("y", v)
  local v = coroutine.yield(101)
  print("z", v)
  return 102
end)

print("a")
local r, v = coroutine.resume(thread, 200)
print("b", r, v)
local r, v = coroutine.resume(thread, 201)
print("c", r, v)
local r, v = coroutine.resume(thread, 202)
print("d", r, v)
local r, v = coroutine.resume(thread, 203)
print("e", r, v)

local metatable = {
  __add = function (a, b)
    local v = coroutine.yield()
    return v + a[1] + b[1]
  end;
}

local thread = coroutine.create(function ()
  local a = setmetatable({ 17 }, metatable)
  local b = setmetatable({ 23 }, metatable)
  print("A")
  local v = a + b
  print("B", v)
end)

coroutine.resume(thread)
coroutine.resume(thread, 42)
