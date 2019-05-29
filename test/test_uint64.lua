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

local uint64_data
local result, module = pcall(require, "test.uint64_data")
if result then
  uint64_data = module
end

local verbose = os.getenv "VERBOSE" == "1"

assert(uint64() == uint64(0, 0))
assert(uint64(0) == uint64(0, 0))
assert(uint64(0, 0) == uint64(0, 0))
assert(uint64(0xFFFFFFFF) == uint64(0x0000, 0x0000FFFFFFFF))
assert(uint64(0xFFFFFFFFFFFF) == uint64(0x0000, 0xFFFFFFFFFFFF))
assert(uint64(0xFFFE, 0x1FFFFFFFFFFFF) == uint64(0xFFFF, 0xFFFFFFFFFFFF))
assert(uint64(0xFFFD, 0x2FFFFFFFFFFFF) == uint64(0xFFFF, 0xFFFFFFFFFFFF))
assert(uint64(0xFFFC, 0x3FFFFFFFFFFFF) == uint64(0xFFFF, 0xFFFFFFFFFFFF))

assert(uint64(0x0000, 0x000000000000):encode_hex() == "0x0000000000000000")
assert(uint64(0x0000, 0xFFFFFFFFFFFF):encode_hex() == "0x0000FFFFFFFFFFFF")
assert(uint64(0xFFFF, 0xFFFFFFFFFFFF):encode_hex() == "0xFFFFFFFFFFFFFFFF")
assert(uint64(0xDEAD, 0xBEEFFEEDFACE):encode_hex() == "0xDEADBEEFFEEDFACE")

assert(uint64(0x0000, 0x000000000000):encode_dec() == "0")
assert(uint64(0x0000, 0xFFFFFFFFFFFF):encode_dec() == "281474976710655")
assert(uint64(0xFFFF, 0xFFFFFFFFFFFF):encode_dec() == "18446744073709551615")
assert(uint64(0xDEAD, 0xBEEFFEEDFACE):encode_dec() == "16045690985374415566")

local uint64_max = uint64(0xFFFF, 0xFFFFFFFFFFFF)
assert(uint64_max * uint64_max == uint64(0, 1))
assert(uint64_max * uint64(0, 2) == uint64(0xFFFF, 0xFFFFFFFFFFFE))

if uint64_data then
  local source = uint64_data.source
  local n = #source

  local function test_binop(op)
    local result = uint64_data[op]
    local f = uint64[op]

    local ok = 0
    local ng = 0

    local k = 0
    for i = 1, n do
      for j = 1, n do
        k = k + 1
        local x = source[i]
        local y = source[j]
        local z = result[k]

        local z1, z2 = f(x[1], x[2], y[1], y[2])
        assert(z1 == z[1])
        assert(z2 == z[2])
      end
    end

    if verbose then
      print("test_binop " .. op)
    end
  end

  test_binop "mul"
end
