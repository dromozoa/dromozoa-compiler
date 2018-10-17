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

local error_message = require "dromozoa.parser.error_message"

local lua53_lexer = require "dromozoa.compiler.lua53_lexer"
local lua53_parser = require "dromozoa.compiler.lua53_parser"
local tree = require "dromozoa.compiler.tree"

local lexer = lua53_lexer()
local parser = lua53_parser()

local source_file, html_file, text_file = ...
local handle = assert(io.open(source_file))
local source = handle:read "*a"
handle:close()

local terminal_nodes, message, i = lexer(source)
if not terminal_nodes then
  error(error_message(message, source, i, source_file))
end
local accepted_node, message, i = parser(terminal_nodes)
if not accepted_node then
  for i = 1, #terminal_nodes do
    local node = terminal_nodes[i]
    print(parser.symbol_names[node[0]], node.p, node.i, node.j)
  end
  error(error_message(message, source, i, source_file))
end

local t = tree(parser, source, terminal_nodes, accepted_node)
local result, message, i = t:resolve()
if not result then
  error(error_message(message, source, i, source_file))
end
t:write_html(html_file)

local out = assert(io.open(text_file, "w"))
local protos = t.protos
for i = 1, #protos do
  local proto = protos[i]
  out:write(proto[1], "\n")

  if proto.parent[1] then
    out:write("  parent ", tostring(proto.parent[1]), "\n")
  end
  if proto.self then
    out:write "  self\n"
  end
  if proto.vararg then
    out:write "  vararg\n"
  end

  if proto.constants[1] then
    out:write "  constants\n"
    for j = 1, #proto.constants do
      local constant = proto.constants[j]
      out:write(("    %s %q %s\n"):format(constant[1], constant.source, constant.type))
      if constant.refs[1] then out:write("      refs ", table.concat(constant.refs, ", "), "\n") end
    end
  end

  if proto.names[1] then
    out:write "  names\n"
    for j = 1, #proto.names do
      local name = proto.names[j]
      out:write(("    %s %q\n"):format(name[1], name.source))
      if name.defs[1] then out:write("      defs ", table.concat(name.defs, ","), "\n") end
      if name.refs[1] then out:write("      refs ", table.concat(name.refs, ","), "\n") end
      if name.updefs[1] then out:write("      updefs ", table.concat(name.updefs, ","), "\n") end
      if name.uprefs[1] then out:write("      uprefs ", table.concat(name.uprefs, ","), "\n") end
    end
  end

  if proto.labels[1] then
    out:write "  labels\n"
    for j = 1, #proto.labels do
      local label = proto.labels[j]
      out:write(("    %s %q\n"):format(label[1], label.source))
      if label.defs[1] then out:write("      defs ", table.concat(label.defs, ","), "\n") end
      if label.refs[1] then out:write("      refs ", table.concat(label.refs, ","), "\n") end
    end
  end

  if proto.upvalues[1] then
    out:write "  upvalues\n"
    for j = 1, #proto.upvalues do
      local upvalue = proto.upvalues[j]
      out:write(("    %s %s (%s %q)\n"):format(upvalue[1], upvalue[2], upvalue.name[1], upvalue.name.source))
    end
  end

  out:write "\n"
end
out:close()
