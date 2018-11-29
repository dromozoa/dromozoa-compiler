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

local variable = require "dromozoa.compiler.variable"

local unpack = table.unpack or unpack

local heads = { "cont_t k", "thread_t t", "handler_t h" }
local head_types = { "cont_t", "thread_t", "handler_t" }
local head_names = { "k", "t", "h" }

local function make_tuple(refs, params)
  local tuple = {}

  for encoded_var, param in pairs(params) do
    local var
    if type(param) == "table" then
      if param.phi then
        var = param[0]
      else
        var = param
      end
    else
      var = variable.decode(encoded_var)
    end
    local item = { var = var }
    if refs[encoded_var] then
      item.type = "ref_t"
    elseif var.type == "array" then
      item.type = "array_t"
    else
      item.type = "value_t"
    end
    tuple[#tuple + 1] = item
  end
  table.sort(tuple, function (a, b) return a.var < b.var end)

  return tuple
end

local function encode_tuple(tuple, heads)
  local buffer = {}
  if heads then
    for i = 1, #heads do
      buffer[i] = heads[i]
    end
  end
  local n = #buffer
  for i = 1, #tuple do
    local item = tuple[i]
    buffer[n + i] = item.type .. " " .. item.var:encode()
  end
  return table.concat(buffer, ", ")
end

local function encode_tuple_types(tuple, heads)
  local buffer = {}
  if heads then
    for i = 1, #heads do
      buffer[i] = heads[i]
    end
  end
  local n = #buffer
  for i = 1, #tuple do
    buffer[n + i] = tuple[i].type
  end
  return table.concat(buffer, ", ")
end

local function encode_tuple_names(tuple, heads)
  local buffer = {}
  if heads then
    for i = 1, #heads do
      buffer[i] = heads[i]
    end
  end
  local n = #buffer
  for i = 1, #tuple do
    buffer[n + i] = tuple[i].var:encode()
  end
  return table.concat(buffer, ", ")
end

local function generate_declations(out, proto_name, blocks, postorder)
  local g = blocks.g
  local u = g.u
  local u_after = u.after
  local refs = blocks.refs

  for i = #postorder, 1, -1 do
    local uid = postorder[i]
    out:write(([[
std::function<void()> %s_%d(%s);
]]):format(proto_name, uid, encode_tuple(make_tuple(refs, blocks[uid].params), heads)))
  end
end

local function generate_closure(out, self)
  local proto_name = self[1]
  local upvalues = self.upvalues
  local blocks = self.blocks
  local entry_uid = blocks.entry_uid
  local refs = blocks.refs

  local proto_tuple = make_tuple(refs, blocks[entry_uid].params)

  local proto_param_tuple = {}
  for i = 0, self.A - 1 do
    local var = variable.A(i)
    if refs[var:encode()] then
      proto_param_tuple[#proto_param_tuple + 1] = { type = "ref_t", var = var }
    else
      proto_param_tuple[#proto_param_tuple + 1] = { type = "value_t", var = var }
    end
  end
  for i = 0, self.V - 1 do
    proto_param_tuple[#proto_param_tuple + 1] = { type = "array_t", var = variable.V(i) }
  end

  local closure_param_tuple = {}
  for i = 1, #upvalues do
    closure_param_tuple[i] = { type = "ref_t", var = upvalues[i][1] }
  end

  local proto_types = encode_tuple_types(proto_param_tuple, head_types)
  local proto_params = encode_tuple(proto_param_tuple, heads)
  local closure_params = encode_tuple(closure_param_tuple)
  local proto_args = encode_tuple_names(proto_tuple, head_names)

  out:write(([[
std::function<std::function<void()>(%s)> %s(%s) {
  return [=](%s) -> std::function<void()> {
    return %s_%d(%s);
  };
}
]]):format(proto_types, proto_name, closure_params, proto_params, proto_name, entry_uid, proto_args))
end

return function (self, out)
  local blocks = self.blocks
  local g = blocks.g
  local uv_postorder = g:uv_postorder(blocks.entry_uid)
  generate_declations(out, self[1], blocks, uv_postorder)
  generate_closure(out, self)
  return out
end
