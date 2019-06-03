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

local K = { [0] = 1 }
for i = 1, 48 do
  K[i] = K[i - 1] * 2
end

local K12 = K[12]
local K16 = K[16]
local K24 = K[24]
local K32 = K[32]
local K36 = K[36]
local K40 = K[40]
local K48 = K[48]

local M16 = K[16] - 1
local M48 = K[48] - 1

local D7 = 10000000

local class = {}

function class.eq(x1, x2, y1, y2)
  return x1 == y1 and x2 == y2
end

function class.lt(x1, x2, y1, y2)
  if x1 == y1 then
    return x2 < y2
  else
    return x1 < y1
  end
end

function class.le(x1, x2, y1, y2)
  if x1 == y1 then
    return x2 <= y2
  else
    return x1 <= y1
  end
end

function class.add(x1, x2, y1, y2)
  local u2 = x2 + y2
  local u1 = x1 + y1

  if u2 >= K48 then
    u2 = u2 - K48
    u1 = u1 + 1
  end
  if u1 >= K16 then
    u1 = u1 - K16
  end

  return u1, u2
end

function class.sub(x1, x2, y1, y2)
  local u2 = x2 - y2
  local u1 = x1 - y1

  if u2 < 0 then
    u2 = u2 + K48
    u1 = u1 - 1
  end
  if u1 < 0 then
    u1 = u1 + K16
  end

  return u1, u2
end

function class.mul(x1, x2, y1, y2)
  local x3 = x2 % K24
  local x2 = (x2 - x3) / K24
  local y3 = y2 % K24
  local y2 = (y2 - y3) / K24

  local u3 = x3 * y3
  local u2 = x3 * y2 + x2 * y3
  local u1 = x3 * y1 + x2 * y2 + x1 * y3

  local v2 = u2 % K24
  local v1 = (u2 - v2) / K24

  local w2 = v2 * K24 + u3
  local w1 = u1 + v1

  if w2 >= K48 then
    w2 = w2 - K48
    w1 = w1 + 1
  end

  return w1 % K16, w2
end

function class.div(X1, X2, Y1, Y2)
  local x2 = X2 % K12
  local x1 = X1 * K36 + (X2 - x2) / K12

  if Y1 == 0 and Y2 < K40 then
    local r1 = x1 % Y2
    local q1 = (x1 - r1) / Y2

    local u = r1 * K12 + x2

    local r2 = u % Y2
    local q2 = (u - r2) / Y2

    local v2 = q1 % K36
    local v1 = (q1 - v2) / K36

    local w2 = q2 % K48
    local w1 = (q2 - w2) / K48

    local z2 = v2 * K12 + w2
    local z1 = v1 + w1

    if z2 >= K48 then
      z2 = z2 - K48
      z1 = z1 + 1
    end

    return z1 % K16, z2, 0, r2
  else
    local y2 = Y2 % K12
    local y1 = Y1 * K36 + (Y2 - y2) / K12

    local q = x1 / (y1 + 1)
    local q = q - q % 1

    -- local U = Y * q
    local y3 = Y2 % K24
    local y2 = (Y2 - y3) / K24

    local u3 = y3 * q
    local u2 = y2 * q
    local u1 = Y1 * q

    local v2 = u2 % K24
    local v1 = (u2 - v2) / K24

    local U2 = v2 * K24 + u3
    local U1 = u1 + v1

    if U2 >= K48 then
      U2 = U2 - K48
      U1 = U1 + 1
    end

    -- local V = X - U
    local V2 = X2 - U2
    local V1 = X1 - U1

    if V2 < 0 then
      V2 = V2 + K48
      V1 = V1 - 1
    end

    if V1 == Y1 then
      if V2 < Y2 then
        return 0, q, V1, V2
      end
    else
      if V1 < Y1 then
        return 0, q, V1, V2
      end
    end

    -- local V = V - Y
    local V2 = V2 - Y2
    local V1 = V1 - Y1
    if V2 < 0 then
      V2 = V2 + K48
      V1 = V1 - 1
    end
    return 0, q + 1, V1, V2
  end
end

function class.shl(x1, x2, y)
  local x3 = x2 % K24

  if y < 48 then
    local x2 = (x2 - x3) / K24

    if y < 24 then
      local k = K[y]

      local u3 = x3 * k
      local u2 = x2 * k
      local u1 = x1 * k

      local v2 = u2 % K24
      local v1 = (u2 - v2) / K24

      local w2 = v2 * K24 + u3
      local w1 = u1 + v1

      if w2 >= K48 then
        w2 = w2 - K48
        w1 = w1 + 1
      end

      return w1 % K16, w2
    else
      local k = K[y - 24]

      local u2 = x3 * k
      local u1 = x2 * k

      local v2 = u2 % K24
      local v1 = (u2 - v2) / K24

      local w2 = v2 * K24
      local w1 = u1 + v1

      return w1 % K16, w2
    end
  else
    local k = K[y - 48]
    local u1 = x3 * k
    return u1 % K16, 0
  end
end

function class.shr(X1, X2, y)
  if y < 48 then
    local x2 = X2 % K16
    local x1 = X1 * K32 + (X2 - x2) / K16

    if y < 16 then
      local k = K[y]

      local r1 = x1 % k
      local q1 = (x1 - r1) / k

      local u = r1 * K16 + x2

      local r2 = u % k
      local q2 = (u - r2) / k

      local v2 = q1 % K32
      local v1 = (q1 - v2) / K32

      return v1, v2 * K16 + q2
    else
      local k = K[y - 16]

      local r1 = x1 % k
      local q1 = (x1 - r1) / k

      return 0, q1
    end
  else
    local k = K[y - 48]

    local r1 = X1 % k
    local q1 = (X1 - r1) / k

    return 0, q1
  end
end

function class.bnot(x1, x2)
  return M16 - x1, M48 - x2
end

function class.encode_dec(X1, X2)
  local x2 = X2 % K24
  local x1 = X1 * K24 + (X2 - x2) / K24

  local r1 = x1 % D7
  local q1 = (x1 - r1) / D7

  local u = r1 * K24 + x2

  local r2 = u % D7
  local q2 = (u - r2) / D7

  local v = q1 * K24 + q2

  if v == 0 then
    return ("%d"):format(r2)
  else
    return ("%d%07d"):format(v, r2)
  end
end

function class.encode_hex(x1, x2)
  return ("0x%04X%012X"):format(x1, x2)
end

return class
