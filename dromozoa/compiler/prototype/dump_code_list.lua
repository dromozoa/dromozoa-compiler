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

local element = require "dromozoa.dom.element"
local space_separated = require "dromozoa.dom.space_separated"
local dump_header = require "dromozoa.compiler.prototype.dump_header"

local _ = element

local function dump_code_list(buffer, code_list, indent)
  if code_list[1] then
    buffer[#buffer + 1] = _"span" { indent .. "code_list {\n" }

    local block_indent = indent .. "  "
    for i = 1, #code_list do
      local code = code_list[i]
      local node_id = code.node_id
      local encoded_vars = {}
      for i = 1, #code do
        encoded_vars[i] = code[i]:encode()
      end
      buffer[#buffer + 1] = _"span" {
        block_indent;
        _"span" {
          class = space_separated { "node", "node" .. node_id };
          ["data-node-id"] = node_id;
          ("%s %s"):format(code[0], table.concat(encoded_vars, " "));
        };
        "\n";
      }
    end

    buffer[#buffer + 1] = _"span" { indent .. "}\n" }
  end
end

return function (buffer, self, indent)
  buffer[#buffer + 1] = _"span" { indent .. ("%s {\n"):format(self[1]:encode()) }

  local block_indent = indent .. "  "
  dump_header(buffer, self, block_indent, true)
  dump_code_list(buffer, self.code_list, block_indent)

  buffer[#buffer + 1] = _"span" { indent .. "}\n" }
  return buffer
end