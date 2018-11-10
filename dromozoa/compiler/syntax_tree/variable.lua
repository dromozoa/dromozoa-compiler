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

local map = {
  P     = { "proto",     1 };
  L     = { "label",     1 };
  M     = { "label",     1 };
  NIL   = { "constant",  0 };
  FALSE = { "constant",  0 };
  TRUE  = { "constant",  0 };
  K     = { "constant",  1 };
  U     = { "upvalue",   1 };
  A     = { "value",     1 };
  B     = { "value",     1 };
  C     = { "value",     1 };
  V     = { "array",     1 };
  T     = { "array",     1 };
}

local class = {}
local metatable = { __index = class }

function class.decode(source)
  if type(source) == "number" then
    assert(source % 1 == 0) -- assert is integer
    return setmetatable({ value = source }, metatable)
  else
    assert(type(source) == "string")
    local key, i, j = source:match "^(%u+)(%d+)%[%d+%]$"
    if not key then
      key, i = source:match "^(%u+)(%d+)$"
    end
    if not key then
      key = assert(source:match "^%u+$")
    end
    local n = assert(map[key][2])
    if n == 0 then
      assert(not i)
      assert(not j)
      return class[key]
    elseif n == 1 then
      assert(not j)
      return class[key](assert(tonumber(i)))
    else
      assert(n == 2)
      return class[key](assert(tonumber(i)), assert(tonumber(j)))
    end
  end
end

function class:encode()
  local key = self.key
  local n = map[key][2]
  if n == 0 then
    return key
  elseif n == 1 then
    return key .. self.i
  elseif n == 2 then
    return key .. self.i .. "[" .. self.j .. "]"
  else
    error ""
  end
end

function metatable:__tostring()
  class.encode(self)
end

for key, def in pairs(map) do
  local n = def[2]
  if n == 0 then
    class[key] = setmetatable({ key = key }, metatable)
  elseif n == 1 then
    class[key] = function (i)
      return setmetatable({ key = key, i = i }, metatable)
    end
  elseif n == 2 then
    class[key] = function (i, j)
      return setmetatable({ key = key, i = i, j = j }, metatable)
    end
  end
end

return class
