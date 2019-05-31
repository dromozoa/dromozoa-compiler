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
local unix = require "dromozoa.unix"

local uint64_data
local result, module_or_message = pcall(require, "test.uint64_data")
if result then
  uint64_data = module_or_message
else
  print(module_or_message)
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

assert(uint64.encode_hex(0x0000, 0x000000000000) == "0x0000000000000000")
assert(uint64.encode_hex(0x0000, 0xFFFFFFFFFFFF) == "0x0000FFFFFFFFFFFF")
assert(uint64.encode_hex(0xFFFF, 0xFFFFFFFFFFFF) == "0xFFFFFFFFFFFFFFFF")
assert(uint64.encode_hex(0xDEAD, 0xBEEFFEEDFACE) == "0xDEADBEEFFEEDFACE")

assert(uint64.encode_dec(0x0000, 0x000000000000) == "0")
assert(uint64.encode_dec(0x0000, 0xFFFFFFFFFFFF) == "281474976710655")
assert(uint64.encode_dec(0xFFFF, 0xFFFFFFFFFFFF) == "18446744073709551615")
assert(uint64.encode_dec(0xDEAD, 0xBEEFFEEDFACE) == "16045690985374415566")

local uint64_max = uint64(0xFFFF, 0xFFFFFFFFFFFF)
assert(uint64_max * uint64_max == uint64(1))
assert(uint64_max * uint64(2) == uint64(0xFFFF, 0xFFFFFFFFFFFE))

assert(uint64_max / uint64(1) == uint64_max)
assert(uint64_max % uint64(1) == uint64(0))
assert(uint64_max / uint64(2) == uint64(0x7FFF, 0xFFFFFFFFFFFF))
assert(uint64_max % uint64(2) == uint64(1))
assert(uint64_max / uint64(0x8000, 0) == uint64(1))
assert(uint64_max % uint64(0x8000, 0) == uint64(0x7FFF, 0xFFFFFFFFFFFF))
assert(uint64(1, 0) / uint64(1, 0) == uint64(1))

if uint64_data then
  local source = uint64_data.source
  local n = #source
  local timer = unix.timer()

  local function test_binop(op)
    local result = uint64_data[op]
    local f = uint64[op]

    timer:start()

    local k = 0
    for i = 1, n do
      for j = 1, n do
        k = k + 1
        local x = source[i]
        local y = source[j]
        local z = result[k]

        if op == "div" then
          if y[1] ~= 0 or y[2] ~= 0 then
            local p = z[1]
            local r = z[2]

            local p1, p2, r1, r2 = f(x[1], x[2], y[1], y[2])
            assert(p1 == p[1])
            assert(p2 == p[2])
            assert(r1 == r[1])
            assert(r2 == r[2])
          end
        else
          local z1, z2 = f(x[1], x[2], y[1], y[2])
          assert(z1 == z[1])
          assert(z2 == z[2])
        end
      end
    end

    timer:stop()

    if verbose then
      print("test_binop", op, timer:elapsed())
    end
  end

  test_binop "add"
  test_binop "sub"
  test_binop "mul"
  test_binop "div"
end
