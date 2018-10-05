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

local source_file, result_file = ...
local handle = assert(io.open(source_file))
local source = handle:read "*a"
handle:close()

local terminal_nodes, message, i = lexer(source)
if not terminal_nodes then
  error(error_message(message, source, i, source_file))
end
local accepted_node, message, i = parser(terminal_nodes)
if not accepted_node then
  error(error_message(message, source, i, source_file))
end

local t = tree(parser, source, terminal_nodes, accepted_node)
-- t:construct_path()

t:write_html(result_file)
