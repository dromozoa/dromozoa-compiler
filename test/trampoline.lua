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

--
-- original
--

local function mul(x, y)
  return x * y
end

local function main(a)
  local r = 1
  local i = 1
  ::L1::
  if i == 11 then
    return r
  end
  r = mul(r, a[i])
  i = i + 1
  print(i, r)
  goto L1
end

print(main({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }))

--
-- ssa
--

local mul = {}

function mul:start(x, y)
  return self:b1(x, y)
end

function mul:b1(x, y)
  return x * y
end

local main = {}

function main:start(a)
  return self:b1(a)
end

function main:b1(a)
  local r = 1
  local i = 1
  return self:b2(a, r, i)
end

function main:b2(a, r, i)
  if i == 11 then
    return r
  else
    return self:b3(a, r, i)
  end
end

function main:b3(a, r, i)
  r = mul:start(r, a[i])
  return self:b4(a, r, i)
end

function main:b4(a, r, i)
  i = i + 1
  return main:b5(a, r, i)
end

function main:b5(a, r, i)
  print(i, r)
  return main:b2(a, r, i)
end

print(main:start({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }))
