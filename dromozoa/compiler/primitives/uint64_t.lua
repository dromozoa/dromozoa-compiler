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
local band = uint64.band
local bor = uint64.bor
local bxor = uint64.bxor
local bnot = uint64.bnot
local shl = uint64.shl
local shr = uint64.shr
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

function class.add(x, ...)
  local x1, x2 = normalize(x)
  return construct(add(x1, x2, normalize(...)))
end

function class.sub(x, ...)
  local x1, x2 = normalize(x)
  return construct(sub(x1, x2, normalize(...)))
end

function class.mul(x, ...)
  local x1, x2 = normalize(x)
  return construct(mul(x1, x2, normalize(...)))
end

function class.div(x, ...)
  local x1, x2 = normalize(x)
  local q1, q2, r1, r2 = construct(div(x1, x2, normalize(...)))
  return construct(q1, q2), construct(r1, r2)
end

function class.band(x, ...)
  local x1, x2 = normalize(...)
  return construct(band(x1, x2, normalize(...)))
end

function class.bor(x, ...)
  local x1, x2 = normalize(x)
  return construct(bor(x1, x2, normalize(...)))
end

function class.bxor(x, ...)
  local x1, x2 = normalize(x)
  return construct(bxor(x1, x2, normalize(...)))
end

function class.bnot(...)
  return construct(bnot(normalize(...)))
end

function class.shl(x, ...)
  local x1, x2 = normalize(x)
  return construct(shl(x1, x2, ...))
end

function class.shr(x, ...)
  local x1, x2 = normalize(x)
  return construct(shr(x1, x2, ...))
end

function class.eq(x, ...)
  local x1, x2 = normalize(x)
  return eq(x1, x2, normalize(...))
end

function class.lt(x, ...)
  local x1, x2 = normalize(x)
  return lt(x1, x2, normalize(...))
end

function class.le(x, ...)
  local x1, x2 = normalize(x)
  return le(x1, x2, normalize(...))
end

function class.encode_dec(...)
  return encode_dec(normalize(...))
end

function class.encode_hex(...)
  return encode_hex(normalize(...))
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
