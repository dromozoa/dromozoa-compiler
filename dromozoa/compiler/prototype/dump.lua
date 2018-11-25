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
local matrix3 = require "dromozoa.vecmath.matrix3"
local path_data = require "dromozoa.svg.path_data"
local variable = require "dromozoa.compiler.variable"
local dump_header = require "dromozoa.compiler.prototype.dump_header"

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

local function dump_block(blocks, uid, block)
  local g = blocks.g
  local uv = g.uv
  local uv_after = uv.after
  local uv_target = uv.target
  local vu = g.vu
  local vu_after = vu.after
  local vu_target = vu.target

  local html = _"span" {
    class = space_separated { "node", "node" .. uid };
    ["data-node-id"] = uid;
    ("  b%d {\n"):format(uid);
  }

  if block.entry then
    html[#html + 1] = "    [entry]\n"
  end

  local pred = {}
  local eid = vu.first[uid]
  while eid do
    local vid = vu_target[eid]
    pred[#pred + 1] = ("b%d"):format(vid)
    eid = vu_after[eid]
  end
  if pred[1] then
    html[#html + 1] = ("    [pred %s]\n"):format(table.concat(pred, " "))
  end

  local label = block.label
  if label then
    html[#html + 1] = ("    [label %s]\n"):format(label:encode())
  end

  -- local dom = {}
  -- for vid in pairs(block.dom) do
  --   dom[#dom + 1] = vid
  -- end
  -- if dom[1] then
  --   table.sort(dom)
  --   html[#html + 1] = ("    [dom b%s]\n"):format(table.concat(dom, " b"))
  -- end

  -- local df = {}
  -- for vid in pairs(block.df) do
  --   df[#df + 1] = vid
  -- end
  -- if df[1] then
  --   table.sort(df)
  --   html[#html + 1] = ("    [df b%s]\n"):format(table.concat(df, " b"))
  -- end

  local params = {}
  for encoded_var in pairs(block.params) do
    params[#params + 1] = variable.decode(encoded_var)
  end
  if params[1] then
    table.sort(params)
    for i = 1, #params do
      params[i] = params[i]:encode()
    end
    html[#html + 1] = ("    [params %s]\n"):format(table.concat(params, " "))
  end

  for i = 1, #block do
    local code = block[i]
    local encoded_vars = {}
    for j = 1, #code do
      encoded_vars[j] = code[j]:encode()
    end
    html[#html + 1] = ("    %s %s\n"):format(code[0], table.concat(encoded_vars, " "))
  end

  -- local live = {}
  -- for encoded_var in pairs(block.live_out) do
  --   live[#live + 1] = variable.decode(encoded_var)
  -- end
  -- if live[1] then
  --   table.sort(live)
  --   for i = 1, #live do
  --     live[i] = live[i]:encode()
  --   end
  --   html[#html + 1] = ("    [live_out %s]\n"):format(table.concat(live, " "))
  -- end

  local label = block["goto"]
  if label then
    html[#html + 1] = ("    [goto %s]\n"):format(label:encode())
  end

  local succ = {}
  local eid = uv.first[uid]
  while eid do
    local vid = uv_target[eid]
    succ[#succ + 1] = ("b%d"):format(vid)
    eid = uv_after[eid]
  end
  if succ[1] then
    html[#html + 1] = ("    [succ %s]\n"):format(table.concat(succ, " "))
  end

  if block.exit then
    html[#html + 1] = "    [exit]\n"
  end

  html[#html + 1] = "  }\n"
  return html
end

local function dump_code(self)
  local blocks = self.blocks
  local g = blocks.g
  local u = g.u
  local u_after = u.after

  local html = _"div" {
    class = "text";
    _"span" { ("%s {\n"):format(self[1]:encode()) };
  }
  dump_header(html, self, "  ")

  local uid = u.first
  while uid do
    html[#html + 1] = dump_block(blocks, uid, blocks[uid])
    uid = u_after[uid]
  end

  html[#html + 1] = _"span" { "}\n" }
  return html
end

local function dump_graph(proto, width, height)
  local blocks = proto.blocks
  local g = blocks.g
  local u = g.u
  local u_after = u.after
  local u_labels = {}

  local uid = u.first
  while uid do
    u_labels[uid] = ("b%d"):format(uid)
    uid = u_after[uid]
  end

  local root = g:render {
    matrix = matrix3(80, 0, 40, 0, 50, 25, 0, 0, 1);
    u_labels = u_labels;
    e_labels = blocks.jumps;
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

  local e_paths = root[3]
  e_paths.class = space_separated { "e_paths", "arrow" }

  local e_texts = root[4]
  e_texts.class = nil
  e_texts.id = "e_texts"
  local defs = _"defs" { marker, e_texts }

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
        e_paths;
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

return function (self, out)
  local doc = html5_document(_"html" {
    head;
    _"body" {
      _"div" {
        class = "root";
        dump_code(self);
      };
      dump_graph(self, 800, 640);
    };
  })
  doc:serialize(out)
  out:write "\n"
  return out
end
