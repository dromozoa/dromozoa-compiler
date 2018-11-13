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

local function dump_code(buffer, block, indent)
  if block[1] then
    buffer[#buffer + 1] = indent .. "code {\n"

    local block_indent = indent .. "  "
    for i = 1, #block do
      local code = block[i]
      local encoded_vars = {}
      for i = 1, #code do
        encoded_vars[i] = code[i]:encode()
      end
      buffer[#buffer + 1] = block_indent .. ("%s %s\n"):format(code[0], table.concat(encoded_vars, " "))
    end

    buffer[#buffer + 1] = indent .. "}\n"
  end
end

return function (buffer, self, indent)
  buffer[#buffer + 1] = indent .. ("%s {\n"):format(self[1]:encode())

  local block_indent = indent .. "  "
  dump_header(buffer, self, block_indent)
  dump_code(buffer, self.code, block_indent)

  buffer[#buffer + 1] = indent .. "}\n"
  return buffer
end
