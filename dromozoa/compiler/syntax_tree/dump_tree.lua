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
local graph = require "dromozoa.graph"
local symbol_value = require "dromozoa.parser.symbol_value"
local matrix3 = require "dromozoa.vecmath.matrix3"
local dump_source = require "dromozoa.compiler.syntax_tree.dump_source"

local _ = element

local keys = {
  "binop";
  "unop";
  "self";
  "vararg";
  "inorder";

  "parlist";
  "param";
  "declare";
  "key";
  "def";
  "use";
  "adjust";

  "var";
  "vars";
}

local head = _"head" {
  _"meta" {
    charset = "UTF-8";
  };
  _"title" {
    "dromozoa-compiler";
  };
  _"link" { rel = "stylesheet"; href = "dromozoa-compiler.css" };
  _"script" { src = "https://cdnjs.cloudflare.com/ajax/libs/jquery/3.3.1/jquery.min.js" };
  _"script" { src = "dromozoa-compiler.js" };
}

local function add_vertices(node, symbol_names, that, labels, nid_to_uid, uid_to_node)
  local nid = node.id
  local uid = that:add_vertex()
  labels[uid] = symbol_names[node[0]]
  nid_to_uid[nid] = uid
  uid_to_node[uid] = node

  for i = 1, #node do
    add_vertices(node[i], symbol_names, that, labels, nid_to_uid, uid_to_node)
  end
end

local function add_edges(node, that, nid_to_uid)
  for i = 1, #node do
    that:add_edge(nid_to_uid[node.id], nid_to_uid[node[i].id])
  end
  for i = 1, #node do
    add_edges(node[i], that, nid_to_uid)
  end
end

local function dump_graph(self, width, height)
  local symbol_names = self.symbol_names
  local accepted_node = self.accepted_node

  local that = graph()
  local labels = {}
  local nid_to_uid = {}
  local uid_to_node = {}

  add_vertices(accepted_node, symbol_names, that, labels, nid_to_uid, uid_to_node)
  add_edges(accepted_node, that, nid_to_uid)

  local root = that:render {
    matrix = matrix3(0, 160, 80, 40, 0, 20, 0, 0, 1);
    u_labels = labels;
    u_max_text_length = 144;
  }

  local u_paths = root[1]
  local u_texts = root[2]
  for i = 1, #u_paths do
    local path = u_paths[i]
    local text = u_texts[i]
    local node = uid_to_node[path["data-uid"]]
    local node_id = node.id
    path["data-node-id"] = node_id
    path["data-source"] = symbol_value(node)
    for j = 1, #keys do
      local key = keys[j]
      path["data-" .. key] = node[key]
    end
    text["data-node-id"] = node_id
  end

  return _"div" {
    class = space_separated { "graph", "tree" };
    _"svg" {
      version = "1.1";
      width = width;
      height = height;
      _"rect" {
        class = "viewport";
        width = width;
        height = height;
        fill = "transparent";
        stroke = "none";
      };
      _"g" {
        class = "view";
        root;
      }
    };
  }
end

return function (self, out)
  local doc = html5_document(_"html" {
    head;
    _"body" {
      _"div" {
        class = "root";
        dump_source(self);
      };
      dump_graph(self, 800, 640);
    };
  })
  doc:serialize(out)
  out:write "\n"
  return out
end
