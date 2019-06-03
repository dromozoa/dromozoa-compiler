-- Copyright (C) 2019 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local uint64 = require "dromozoa.compiler.primitives.uint64"

local add = uint64.add
local sub = uint64.sub
local mul = uint64.mul
local div = uint64.div
local eq = uint64.eq
local lt = uint64.lt
local le = uint64.le
local encode_dec = uint64.encode_dec
local encode_hex = uint64.encode_hex

local K16 = 0x10000
local K48 = 0x1000000000000

local function normalize(X1, X2)
  if X2 then
    local x2 = X2 % K48
    local x1 = (X1 + (X2 - x2) / K48) % K16
    return x1, x2
  elseif X1 then
    if type(X1) == "table" then
      return normalize(X1[1], X1[2])
    else
      local x2 = X1 % K48
      local x1 = (X1 - x2) / K48 % K16
      return x1, x2
    end
  else
    return 0, 0
  end
end

local class = {}
local metatable = { __index = class }

local function construct(x1, x2)
  return setmetatable({ x1, x2 }, metatable)
end

function class.add(x, y)
  local x1, x2 = normalize(x)
  return construct(add(x1, x2, normalize(y)))
end

function class.sub(x, y)
  local x1, x2 = normalize(x)
  return construct(sub(x1, x2, normalize(y)))
end

function class.mul(x, y)
  local x1, x2 = normalize(x)
  return construct(mul(x1, x2, normalize(y)))
end

function class.div(x, y)
  local x1, x2 = normalize(x)
  local q1, q2, r1, r2 = construct(div(x1, x2, normalize(y)))
  return construct(q1, q2), construct(r1, r2)
end

function class.eq(x, y)
  local x1, x2 = normalize(x)
  return eq(x1, x2, normalize(y))
end

function class.lt(x, y)
  local x1, x2 = normalize(x)
  return lt(x1, x2, normalize(y))
end

function class.le(x, y)
  local x1, x2 = normalize(x)
  return le(x1, x2, normalize(y))
end

function class.encode_dec(x)
  return encode_dec(normalize(x))
end

function class.encode_hex(x)
  return encode_hex(normalize(x))
end

metatable.__add = class.add
metatable.__sub = class.sub
metatable.__mul = class.mul
metatable.__eq = class.eq
metatable.__lt = class.lt
metatable.__le = class.le
metatable.__tostring = class.encode_dec

function metatable.__div(x, y)
  local x1, x2 = normalize(x)
  return construct(div(x1, x2, normalize(y)))
end

function metatable.__mod(x, y)
  local x1, x2 = normalize(x)
  local _, _, r1, r2 = div(x1, x2, normalize(y))
  return construct(r1, r2)
end

return setmetatable(class, {
  __call = function (_, ...)
    return construct(normalize(...))
  end;
})
