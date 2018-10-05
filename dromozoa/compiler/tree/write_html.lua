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
local html5_document = require "dromozoa.dom.html5_document"
local space_separated = require "dromozoa.dom.space_separated"

local _ = element

local style = _"style" { [[
@import url('https://fonts.googleapis.com/css?family=Roboto+Mono');

body {
  font-family: 'Roboto Mono', monospace;
  white-space: pre;
}
]]}

local head = _"head" {
  _"meta" {
    charset = "UTF-8";
  };
  _"title" {
    "tree";
  };
  style;
}

return function (self, out)
  local symbol_names = self.symbol_names
  local terminal_nodes = self.terminal_nodes
  local source = self.source

  local source_html = _"div" { class = "source" }
  for i = 1, #terminal_nodes do
    local node = terminal_nodes[i]
    local symbol = node[0]
    local p = node.p
    local i = node.i
    local j = node.j
    local id = node.id
    if id then
      id = "S" .. id
    end
    local path = node.path

    if p < i then
      local prev_path = node.prev_path
      local class = space_separated {}
      for i = 1, #prev_path do
        local id = prev_path[i]
        if id == path[i] then
          class[i] = "S" .. id
        else
          break
        end
      end
      if #class == 0 then
        class = nil
      end
      source_html[#source_html + 1] = _"span" {
        class = class;
        source:sub(p, i - 1);
      }
    end

    if symbol == 1 then -- eof
      break
    end

    local class = space_separated {}
    for i = 1, #path do
      class[i] = "S" .. path[i]
    end
    class[#class + 1] = "S"
    source_html[#source_html + 1] = _"span" {
      id = id;
      class = class;
      source:sub(i, j);
    }
  end

  local doc = html5_document(_"html" {
    head;
    _"body" {
      source_html;
    };
  })

  doc:serialize(out)
  out:write "\n"
  return out
end
