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
local matrix3 = require "dromozoa.vecmath.matrix3"
local path_data = require "dromozoa.svg.path_data"

local _ = element

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

local style = _"style" { [[
.e_paths {
  marker-end: url(#arrow);
}

.e_texts.z1 {
  fill: #E0E0E0;
  stroke: #E0E0E0;
  stroke-width: 4;
}

.e_texts.z2 {
  fill: #000;
  stroke: none;
}
]] }

local marker = _"marker" {
  id = "arrow";
  viewBox = "0 0 4 4";
  refX = 4;
  refY = 2;
  markerWidth = 8;
  markerHeight = 8;
  orient = "auto";
  _"path" {
    d = path_data():M(0,0):L(4,2):L(0,4):Z();
  };
}

local function block_to_code(basic_blocks, uid, block)
  local g = basic_blocks.g
  local uv = g.uv
  local uv_after = uv.after
  local uv_target = uv.target
  local vu = g.vu
  local vu_after = vu.after
  local vu_target = vu.target

  local html = _"span" {
    class = space_separated { "S", "S" .. uid };
    ["data-node-id"] = uid;
    "  BB", uid, " {\n";
  }

  html[#html + 1] = "    [pred";
  local eid = vu.first[uid]
  while eid do
    local vid = vu_target[eid]
    html[#html + 1] = " BB"
    html[#html + 1] = vid
    eid = vu_after[eid]
  end
  html[#html + 1] = "]\n"

  local label = block.label
  if label then
    html[#html + 1] = "    [label "
    html[#html + 1] = label
    html[#html + 1] = "]\n"
  end

  for i = 1, #block do
    local code = block[i]
    html[#html + 1] = "    "
    html[#html + 1] = code[0]
    for j = 1, #code do
      html[#html + 1] = " "
      html[#html + 1] = code[j]
    end
    html[#html + 1] = "\n"
  end

  html[#html + 1] = "    [succ"
  local eid = uv.first[uid]
  while eid do
    local vid = uv_target[eid]
    html[#html + 1] = " BB"
    html[#html + 1] = vid
    eid = uv_after[eid]
  end
  html[#html + 1] = "]\n"

  html[#html + 1] = "  }\n"
  return html
end

local function to_code(proto)
  local basic_blocks = proto.basic_blocks
  local blocks = basic_blocks.blocks

  local html = _"div" {
    class = "code";
    _"span" { proto[1], " {\n" };
  }

  for uid = basic_blocks.entry_uid, basic_blocks.exit_uid do
    local block = blocks[uid]
    if block then
      html[#html + 1] = block_to_code(basic_blocks, uid, block)
    end
  end
  html[#html + 1] = _"span" { "}\n" }

  return html
end

local function to_graph(proto, width, height)
  local basic_blocks = proto.basic_blocks
  local g = basic_blocks.g

  local u_labels = {}
  for uid = basic_blocks.entry_uid, basic_blocks.exit_uid do
    u_labels[uid] = "BB" .. uid
  end

  local root = g:render {
    matrix = matrix3(80, 0, 40, 0, 50, 25, 0, 0, 1);
    u_labels = u_labels;
    e_labels = basic_blocks.jumps;
  }

  local u_paths = root[1]
  local u_texts = root[2]
  for i = 1, #u_paths do
    local path = u_paths[i]
    local text = u_texts[i]
    local node_id = path["data-uid"]
    path["data-node-id"] = node_id
    text["data-node-id"] = node_id
  end

  local e_texts = root[4]
  e_texts.class = nil
  e_texts.id = "e_texts"
  local defs = _"defs" { style, marker, e_texts }

  return _"div" {
    class = "graph";
    _"svg" {
      version = "1.1";
      width = width;
      height = height;
      defs;
      _"rect" {
        class = "viewport";
        width = width;
        height = height;
        fill = "transparent";
        stroke = "none";
      };
      _"g" {
        class = "view";
        u_paths;
        u_texts;
        root[3];
        _"use" {
          class = "e_texts z1";
          ["xlink:href"] = "#e_texts";
        };
        _"use" {
          class = "e_texts z2";
          ["xlink:href"] = "#e_texts";
        };
      }
    };
  }
end

return function (proto, out)
  local doc = html5_document(_"html" {
    head;
    _"body" {
      to_code(proto);
      to_graph(proto, 800, 640);
    };
  })
  doc:serialize(out)
  out:write "\n"
  return out
end
