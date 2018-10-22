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

local symbol_value = require "dromozoa.parser.symbol_value"

-- https://tc39.github.io/ecma262/#prod-DoubleStringCharacter
local char_table = {
  ["\n"] = [[\n]];
  ["\r"] = [[\r]];
  ["\\"] = [[\\]];
  ["\""] = [[\"]];
  [string.char(0xE2, 0x80, 0xA8)] = [[\u2028]]; -- LS / LINE SEPARATOR
  [string.char(0xE2, 0x80, 0xA9)] = [[\u2029]]; -- PS / PARAGRAPH SEPARATOR
}

for byte = 0x00, 0x7F do
  local char = string.char(byte)
  if not char_table[char] then
    char_table[char] = ([[\u04X]]):format(byte)
  end
end

local function encode_string(s)
  return "\"" .. s:gsub("[%z\1-\31\127]", char_table):gsub("\226\128[\168\169]", char_table) .. "\""
end

local function write_constants(self, out, proto)
  local constants = proto.constants
  local n = #constants
  out:write(("let %s_K = [\n"):format(proto[1]))
  for j = 1, #constants do
    local constant = constants[j]
    if constant.type == "string" then
      out:write(("/* %s */ %s,\n"):format(constant[1], encode_string(constant.source)))
    else
      out:write(("/* %s */ %.17g,\n"):format(constant[1], tonumber(constant.source)))
    end
  end
  out:write "];\n"
end

local function write_proto(self, out, node, proto)
  local proto_name = proto[1]
  out:write(("let %s = function () {\n"):format(proto_name))

  local constants = proto.constants
  out:write "let K = [\n"
  for j = 1, #constants do
    local constant = constants[j]
    if constant.type == "string" then
      out:write(("/* %s */ %s,\n"):format(constant[1], encode_string(constant.source)))
    else
      out:write(("/* %s */ %.17g,\n"):format(constant[1], tonumber(constant.source)))
    end
  end
  out:write "];\n"

  out:write "};\n";
end

local function write(self, out, node)
  local proto = node.proto
  if proto then
    out:write(("let %s = function () {\n"):format(proto[1]))

    local constants = proto.constants
    out:write "let K = [\n"
    for i = 1, #constants do
      local constant = constants[i]
      if constant.type == "string" then
        out:write(("/* %s */ %s,\n"):format(constant[1], encode_string(constant.source)))
      else
        out:write(("/* %s */ %.17g,\n"):format(constant[1], tonumber(constant.source)))
      end
    end
    out:write "];\n"

    local upvalues = proto.upvalues
    out:write "let U = [\n"
    for i = 1, #upvalues do
      local upvalue = upvalues[i]
      local var = upvalue[2]
      assert(var:find "^[ABCU]%d+$")
      out:write(("/* %s */ [%s,%d],\n"):format(upvalue[1], var:sub(1, 1), var:sub(2)))
    end
    out:write "];\n"

    out:write "let A = [];\n"
    out:write "let B = [];\n"
    out:write "let C = [];\n"
  end

  for i = 1, #node do
    write(self, out, node[i])
  end

  if proto then
    out:write(("/* %s */ };\n"):format(proto[1]))
  end
end

return function (self, out, name)
  out:write(name, " = function (_ENV) {\n")
  out:write "let B = [_ENV];\n"
  write(self, out, self.accepted_node)
  out:write "}\n"
  return out
end
