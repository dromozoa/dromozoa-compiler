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

local dump_header = require "dromozoa.compiler.prototype.dump_header"

local function dump_code(self, out, block, indent)
  out:write(indent, "{\n")
  for i = 1, #block do
    local code = block[i]
    out:write(indent, "  ", code[0])
    for i = 1, #code do
      out:write((" %s"):format(code[i]:encode()))
    end
    out:write "\n"
  end
  out:write(indent, "}\n")
end

return function (self, out, indent)
  if not indent then
    indent = ""
  end

  out:write(indent, ("%s\n"):format(self[1]:encode()))

  local indent = indent .. "  "
  dump_header(self, out, indent)
  dump_code(self, out, self.code, indent)

  return out
end
