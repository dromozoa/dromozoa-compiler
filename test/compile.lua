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
local syntax_tree = require "dromozoa.compiler.syntax_tree"

local lexer = lua53_lexer()
local parser = lua53_parser()

local source_file, output_name = ...
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

local t = syntax_tree(parser, source, terminal_nodes, accepted_node)
local result, message, i = t:analyze()
if not result then
  error(error_message(message, source, i, source_file))
end

local opts = {
  mode = os.getenv "MODE"
}

if not os.getenv "NO_GENERATE" then
  t:generate()
  for i = 1, #t.protos do
    t.protos[i]:generate()
  end
end

if not os.getenv "NO_COMPILE" then
  t:compile_es(output_name .. ".js", opts)
  t:compile_cxx(output_name .. ".cpp", opts)
end

if not os.getenv "NO_DUMP" then
  t:dump_tree(output_name .. ".html")
  t:dump_protos(output_name .. "-protos.txt")
  for i = 1, #t.protos do
    local proto = t.protos[i]
    proto:dump(output_name .. "-" .. proto[1]:encode() .. ".html")
  end
end

local html = os.getenv "OUTPUT_HTML"
local name = os.getenv "OUTPUT_NAME"
if html then
  local out = assert(io.open(html, "w"))
  out:write(([[
  <a href="%s.js">es</a>,
  <a href="%s.cpp">cxx</a>,
  <a href="%s.html">tree</a>,
  <a href="%s-protos.txt">protos</a>,
  bb:
]]):format(name, name, name, name))
  for i = 1, #t.protos do
    local proto = t.protos[i]
    out:write(([[
  <a href="%s-%s.html">%s</a>,
]]):format(name, proto[1]:encode(), proto[1]:encode()))
  end
  out:close()
end
