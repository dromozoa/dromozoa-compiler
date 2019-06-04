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
local uint64_t = require "dromozoa.compiler.primitives.uint64_t"

local unix
local result, module = pcall(require, "dromozoa.unix")
if result then
  -- unix = module
end

local verbose = os.getenv "VERBOSE" == "1"

local uint64_max = uint64_t(0xFFFF, 0xFFFFFFFFFFFF)

assert(uint64_t() == uint64_t(0, 0))
assert(uint64_t(0) == uint64_t(0, 0))
assert(uint64_t(0, 0) == uint64_t(0, 0))
assert(uint64_t(0xFFFFFFFF) == uint64_t(0x0000, 0x0000FFFFFFFF))
assert(uint64_t(0xFFFFFFFFFFFF) == uint64_t(0x0000, 0xFFFFFFFFFFFF))
assert(uint64_t(0xFFFE, 0x1FFFFFFFFFFFF) == uint64_max)
assert(uint64_t(0xFFFD, 0x2FFFFFFFFFFFF) == uint64_max)
assert(uint64_t(0xFFFC, 0x3FFFFFFFFFFFF) == uint64_max)

assert(uint64_t {} == uint64_t(0, 0))
assert(uint64_t { 0 } == uint64_t(0, 0))
assert(uint64_t { 0, 0 } == uint64_t(0, 0))
assert(uint64_t { 0xFFFFFFFF } == uint64_t(0x0000, 0x0000FFFFFFFF))
assert(uint64_t { 0xFFFFFFFFFFFF } == uint64_t(0x0000, 0xFFFFFFFFFFFF))
assert(uint64_t { 0xFFFE, 0x1FFFFFFFFFFFF } == uint64_max)
assert(uint64_t { 0xFFFD, 0x2FFFFFFFFFFFF } == uint64_max)
assert(uint64_t { 0xFFFC, 0x3FFFFFFFFFFFF } == uint64_max)

assert(uint64.tostring_hex(0, 0) == "0x0000000000000000")
assert(uint64.tostring_hex(0x0000, 0x000000000000) == "0x0000000000000000")
assert(uint64.tostring_hex(0x0000, 0xFFFFFFFFFFFF) == "0x0000FFFFFFFFFFFF")
assert(uint64.tostring_hex(0xFFFF, 0xFFFFFFFFFFFF) == "0xFFFFFFFFFFFFFFFF")
assert(uint64.tostring_hex(0xDEAD, 0xBEEFFEEDFACE) == "0xDEADBEEFFEEDFACE")

assert(uint64_t(0x0000, 0x000000000000):tostring_hex() == "0x0000000000000000")
assert(uint64_t(0x0000, 0xFFFFFFFFFFFF):tostring_hex() == "0x0000FFFFFFFFFFFF")
assert(uint64_t(0xFFFF, 0xFFFFFFFFFFFF):tostring_hex() == "0xFFFFFFFFFFFFFFFF")
assert(uint64_t(0xDEAD, 0xBEEFFEEDFACE):tostring_hex() == "0xDEADBEEFFEEDFACE")

assert(uint64.tostring_dec(0, 0) == "0")
assert(uint64.tostring_dec(0x0000, 0x000000000000) == "0")
assert(uint64.tostring_dec(0x0000, 0xFFFFFFFFFFFF) == "281474976710655")
assert(uint64.tostring_dec(0xFFFF, 0xFFFFFFFFFFFF) == "18446744073709551615")
assert(uint64.tostring_dec(0xDEAD, 0xBEEFFEEDFACE) == "16045690985374415566")

assert(uint64_t(0x0000, 0x000000000000):tostring_dec() == "0")
assert(uint64_t(0x0000, 0xFFFFFFFFFFFF):tostring_dec() == "281474976710655")
assert(uint64_t(0xFFFF, 0xFFFFFFFFFFFF):tostring_dec() == "18446744073709551615")
assert(uint64_t(0xDEAD, 0xBEEFFEEDFACE):tostring_dec() == "16045690985374415566")

assert(tostring(uint64_t(0x0000, 0x000000000000)) == "0")
assert(tostring(uint64_t(0x0000, 0xFFFFFFFFFFFF)) == "281474976710655")
assert(tostring(uint64_t(0xFFFF, 0xFFFFFFFFFFFF)) == "18446744073709551615")
assert(tostring(uint64_t(0xDEAD, 0xBEEFFEEDFACE)) == "16045690985374415566")

assert(uint64_max + 1 == uint64_t(0))
assert(uint64_max + 2 == uint64_t(1))
assert(1 + uint64_max == uint64_t(0))
assert(2 + uint64_max == uint64_t(1))

assert(uint64_max - 1 == uint64_t(0xFFFF, 0xFFFFFFFFFFFE))
assert(uint64_max - 2 == uint64_t(0xFFFF, 0xFFFFFFFFFFFD))

assert(uint64_max * uint64_max == uint64_t(1))
assert(uint64_max * uint64_t(2) == uint64_t(0xFFFF, 0xFFFFFFFFFFFE))

assert(uint64_max / uint64_t(1) == uint64_max)
assert(uint64_max % uint64_t(1) == uint64_t(0))
assert(uint64_max / uint64_t(2) == uint64_t(0x7FFF, 0xFFFFFFFFFFFF))
assert(uint64_max % uint64_t(2) == uint64_t(1))
assert(uint64_max / uint64_t(0x8000, 0) == uint64_t(1))
assert(uint64_max % uint64_t(0x8000, 0) == uint64_t(0x7FFF, 0xFFFFFFFFFFFF))
assert(uint64_t(1, 0) / uint64_t(1, 0) == uint64_t(1))

assert(uint64_t(1) < uint64_t(2))
assert(uint64_t(1) <= uint64_t(2))
assert(not (uint64_t(2) < uint64_t(2)))
assert(uint64_t(2) <= uint64_t(2))

assert(uint64_max:shl(16) == uint64_t(0xFFFF, 0xFFFFFFFF0000))
assert(uint64_max:shr(16) == uint64_t(0x0000, 0xFFFFFFFFFFFF))
assert(uint64_max:shl(16):shr(8) == uint64_t(0x00FF, 0xFFFFFFFFFF00))
assert(uint64_max:shr(16):shl(8) == uint64_t(0x00FF, 0xFFFFFFFFFF00))

assert(uint64_t(0x1234, 0x123456789ABC):bnot() == uint64_t(0xEDCB, 0xEDCBA9876543))
assert(uint64_t(0x1234, 0x123456789ABC):bxor(0x1234, 0x123456789ABC) == uint64_t())

local timer
if unix then
  timer = unix.timer()
else
  timer = {}

  function timer:start()
    self[1] = os.clock()
  end

  function timer:stop()
    self[2] = os.clock() - self[1]
  end

  function timer:elapsed()
    return self[2]
  end
end

local function read_dataset(filename)
  local handle = io.open(filename)
  if not handle then
    return
  end

  local op = assert(filename:match "uint64_data_([^%.]+)%.txt$")

  timer:start()
  local dataset = {}
  if op == "div" then
    for line in handle:lines() do
      if line == "" then
        dataset[#dataset + 1] = {}
      else
        local a, b, c, d = assert(line:match "^(0x%x+)\t(0x%x+)\t(0x%x+)\t(0x%x+)$")
        dataset[#dataset + 1] = {
          tonumber(a);
          tonumber(b);
          tonumber(c);
          tonumber(d);
        }
      end
    end
  elseif op:find "^tostring_" then
    for line in handle:lines() do
      dataset[#dataset + 1] = line
    end
  else
    for line in handle:lines() do
      local a, b = assert(line:match "^(0x%x+)\t(0x%x+)$")
      dataset[#dataset + 1] = {
        tonumber(a);
        tonumber(b);
      }
    end
  end
  timer:stop()

  if verbose then
    print("read_dataset", filename, timer:elapsed())
  end

  handle:close()
  return dataset
end

local uint64_data = {
  source = read_dataset "test/uint64_data_source.txt";
  add = read_dataset "test/uint64_data_add.txt";
  sub = read_dataset "test/uint64_data_sub.txt";
  mul = read_dataset "test/uint64_data_mul.txt";
  div = read_dataset "test/uint64_data_div.txt";
  band = read_dataset "test/uint64_data_band.txt";
  bor = read_dataset "test/uint64_data_bor.txt";
  bxor = read_dataset "test/uint64_data_bxor.txt";
  bnot = read_dataset "test/uint64_data_bnot.txt";
  shl = read_dataset "test/uint64_data_shl.txt";
  shr = read_dataset "test/uint64_data_shr.txt";
  tostring_dec = read_dataset "test/uint64_data_tostring_dec.txt";
  tostring_hex = read_dataset "test/uint64_data_tostring_hex.txt";
}

local source = uint64_data.source
if not source then
  os.exit()
end

local n = #source
if verbose then
  print(n)
end

local function test_binop(op)
  local result = uint64_data[op]
  local f = uint64[op]

  timer:start()

  if op == "div" then
    local k = 0
    for i = 1, n do
      for j = 1, n do
        k = k + 1
        local x = source[i]
        local y = source[j]
        local R = result[k]

        local y1 = y[1]
        local y2 = y[2]
        if y1 ~= 0 and y2 ~= 0 then
          local p1, p2, r1, r2 = f(x[1], x[2], y1, y2)
          assert(p1 == R[1])
          assert(p2 == R[2])
          assert(r1 == R[3])
          assert(r2 == R[4])
        end
      end
    end
  else
    local k = 0
    for i = 1, n do
      for j = 1, n do
        k = k + 1
        local x = source[i]
        local y = source[j]
        local R = result[k]

        local z1, z2 = f(x[1], x[2], y[1], y[2])
        assert(z1 == R[1])
        assert(z2 == R[2])
      end
    end
  end

  timer:stop()

  if verbose then
    print("test_binop", op, #result, timer:elapsed())
  end
end

local function test_shift(op)
  local result = uint64_data[op]
  local f = uint64[op]

  timer:start()

  local k = 0
  for i = 1, n do
    for j = 0, 63 do
      k = k + 1
      local x = source[i]
      local R = result[k]

      local z1, z2 = f(x[1], x[2], j)
      -- print(uint64.tostring_hex(x[1], x[2]), j)
      -- print(uint64.tostring_hex(z1, z2))
      -- print(uint64.tostring_hex(R[1], R[2]))
      assert(z1 == R[1])
      assert(z2 == R[2])
    end
  end

  timer:stop()

  if verbose then
    print("test_shift", op, #result, timer:elapsed())
  end
end

local function test_unop(op)
  local result = uint64_data[op]
  local f = uint64[op]

  timer:start()

  local k = 0
  if op:find "^tostring_" then
    for i = 1, n do
      local x = source[i]
      local R = result[i]
      local y = f(x[1], x[2])
      assert(y == R)
    end
  else
    for i = 1, n do
      local x = source[i]
      local R = result[i]
      local y1, y2 = f(x[1], x[2])
      -- print(uint64.tostring_hex(x[1], x[2]))
      -- print(uint64.tostring_hex(y1, y2))
      -- print(uint64.tostring_hex(R[1], R[2]))
      assert(y1 == R[1])
      assert(y2 == R[2])
    end
  end

  timer:stop()

  if verbose then
    print("test_unop", op, #result, timer:elapsed())
  end
end

test_binop "add"
test_binop "sub"
test_binop "mul"
test_binop "div"
test_binop "band"
test_binop "bor"
test_binop "bxor"
test_unop "bnot"
test_shift "shl"
test_shift "shr"
test_unop "tostring_dec"
test_unop "tostring_hex"
