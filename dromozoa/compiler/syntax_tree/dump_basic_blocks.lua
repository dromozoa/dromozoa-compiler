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
local graph = require "dromozoa.graph"
local matrix3 = require "dromozoa.vecmath.matrix3"

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

local function to_code(self)
end

local function to_graph(self, width, height)
end

return function (self, out)
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
