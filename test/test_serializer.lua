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

local variable = require "dromozoa.compiler.variable"
local serializer = require "dromozoa.compiler.serializer"

local verbose = os.getenv "VERBOSE" == "1"

local unpack = table.unpack or unpack

local vars = {
  variable.U(0);
  variable.U(1);
  variable.U(2);
  variable.U(3);
}

local x = serializer.separated ", " { 42, "foo", unpack(vars) }
local s = tostring(x)
if verbose then
  print(s)
end
assert(s == "42, foo, U0, U1, U2, U3")

local x = serializer.separated ", " (serializer.map(vars, function (var)
  local encoded_var = var:encode()
  return ("%s(%s)"):format(encoded_var, encoded_var)
end))
local s = tostring(x)
if verbose then
  print(s)
end
assert(s == "U0(U0), U1(U1), U2(U2), U3(U3)")




