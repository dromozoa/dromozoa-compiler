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

local s = serializer.sequence {
  variable.U(0);
  variable.U(1);
  variable.U(2);
  variable.U(3);
}
:separated ", "
:map(serializer.template "%1(%1)")
:if_not_empty ": "
:encode()

if verbose then
  print(s)
end
assert(s == ": U0(U0), U1(U1), U2(U2), U3(U3)")

serializer.entries {
  a = 17;
  b = 23;
  c = 37;
  d = 42;
}
:sort(function (a, b) return a[1] < b[1] end)
:map(serializer.template "%1=%2")
:separated "\n"
:write(io.stdout)
:write "\n"
