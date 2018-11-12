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

local function prepare_paths(node, parent_path)
  local path = {}
  local n = #parent_path
  for i = 1, n do
    path[i] = parent_path[i]
  end
  path[n + 1] = node.id

  node.path = path

  for i = 1, #node do
    prepare_paths(node[i], path)
  end
end

local function prepare(self)
  local terminal_nodes = self.terminal_nodes
  local accepted_node = self.accepted_node

  prepare_paths(accepted_node, {})

  local n = #terminal_nodes
  local next_path = {}
  for i = n, 1, -1 do
    local node = terminal_nodes[i]
    node.next_path = next_path
    local path = node.path
    if path then
      next_path = path
    end
  end
  local prev_path = {}
  for i = 1, n do
    local node = terminal_nodes[i]
    node.prev_path = prev_path
    local path = node.path
    if path then
      prev_path = path
    else
      local next_path = node.next_path
      local path = {}
      for i = 1, #prev_path do
        local id = prev_path[i]
        if id == next_path[i] then
          path[i] = id
        else
          break
        end
      end
      node.path = path
    end
  end
end

local function to_code(self)
  local terminal_nodes = self.terminal_nodes
  local source = self.source

  local html = _"div" { class = "code" }
  for i = 1, #terminal_nodes do
    local node = terminal_nodes[i]
    local symbol = node[0]
    local p = node.p
    local i = node.i
    local j = node.j
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
      html[#html + 1] = _"span" {
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
    html[#html + 1] = _"span" {
      id = id;
      class = class;
      ["data-node-id"] = node.id;
      source:sub(i, j);
    }
  end

  return html
end

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

local function to_graph(self, width, height)
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
  prepare(self)
  local doc = html5_document(_"html" {
    head;
    _"body" {
      to_code(self);
      to_graph(self, 800, 640);
    };
  })
  doc:serialize(out)
  out:write "\n"
  return out
end
