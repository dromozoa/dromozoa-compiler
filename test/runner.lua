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

local error_message = require "dromozoa.parser.error_message"
local lua53_lexer = require "dromozoa.compiler.lua53_lexer"
local lua53_parser = require "dromozoa.compiler.lua53_parser"
local syntax_tree = require "dromozoa.compiler.syntax_tree"

local q = [[']]
local e = [[\']]
local qeq = q .. e .. q
local eqq = e .. q .. q
local qqe = q .. q .. e

local function shell_quote(v)
  return ((q .. tostring(v):gsub(q, qeq) .. q):gsub(eqq, e):gsub(qqe, e))
end

io.stdout:setvbuf "no"
io.stderr:setvbuf "no"

local lexer = lua53_lexer()
local parser = lua53_parser()

local function compile(source_file, output_name)
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

  t:generate()
  for i = 1, #t.protos do
    t.protos[i]:generate()
  end

  t:dump_tree(output_name .. ".html")
  t:dump_protos(output_name .. "-protos.html")
  for i = 1, #t.protos do
    local proto = t.protos[i]
    proto:dump(output_name .. "-" .. proto[1]:encode() .. ".html", true)
  end

  return t
end

local output_dir = ...
local out = assert(io.open(output_dir .. "/index.html", "w"))
out:setvbuf "no"

out:write [[
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
<title>dromozoa-compiler</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/github-markdown-css/3.0.1/github-markdown.min.css">
<style>
.markdown-body {
  box-sizing: border-box;
  min-width: 200px;
  max-width: 980px;
  margin: 0 auto;
  padding: 45px;
}
@media (max-width: 767px) {
  .markdown-body {
    padding: 15px;
  }
}
</style>
</head>
<body>
<div class="markdown-body">
<h1>dromozoa-compiler</h1>
<h2>execute</h2>
<ul>
]]

for i = 2, #arg do
  local source_file = arg[i]
  local source_name = assert(source_file:match "([^/]+)%.lua$")
  local output_name = output_dir .. "/" .. source_name

  io.write(("compiling %s...\n"):format(source_file))
  local t = compile(source_file, output_name, out)
  local protos = t.protos

  -- generate lua
  -- generate cxx
  -- generate es

  io.write(("executing %s...\n"):format(source_file))
  local result = os.execute(("lua %s >%s 2>&1"):format(
      shell_quote(source_file),
      shell_quote(output_name .. "-expected.txt")))

  -- execute lua
  -- execute cxx
  -- execute es

  out:write(([[
  <li>
    %s
    <a href="%s-tree.html">tree</a>,
    <a href="%s-protos.html">protos</a>,
    bb:
]]):format(source_name, source_name, source_name))
  for i = 1, #protos do
    local proto_name = protos[i][1]:encode()
    out:write(([[
    <a href="%s-%s.html">%s</a>,
]]):format(source_name, proto_name, proto_name))
  end

  -- output lua
  -- output cxx
  -- output es

  out:write(([[
    result:
    <a href="%s-expected.txt">expected</a>
  </li>
]]):format(source_name))
end

out:write [[
</ul>
</body>
</html>
]]
