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

local graph = require "dromozoa.graph"
local variable = require "dromozoa.compiler.variable"

local function generate(code_list)
  local g = graph()
  local entry_uid = g:add_vertex()
  local uid
  local uids = { entry_uid }
  local block
  local blocks = { [entry_uid] = { entry = true } }
  local labels = {}

  for i = 1, #code_list do
    local code = code_list[i]
    local name = code[0]
    if name == "LABEL" then
      uid = g:add_vertex()
      uids[#uids + 1] = uid
      local label = code[1]
      block = { label = label }
      blocks[uid] = block
      labels[label] = uid
    else
      if not uid then
        uid = g:add_vertex()
        uids[#uids + 1] = uid
        block = {}
        blocks[uid] = block
      end
      block[#block + 1] = code
      if name == "RESULT" or name == "RETURN" or name == "GOTO" or name == "COND" then
        uid = nil
      end
    end
  end

  local exit_uid = g:add_vertex()
  uids[#uids + 1] = exit_uid
  blocks[exit_uid] = { exit = true }

  blocks.g = g
  blocks.entry_uid = entry_uid
  blocks.exit_uid = exit_uid
  return blocks, uids, labels
end

local function resolve_jumps(blocks, uids, labels)
  local g = blocks.g
  local exit_uid = blocks.exit_uid

  local jumps = {}

  local this_uid = uids[1]
  for i = 2, #uids do
    local next_uid = uids[i]
    local block = blocks[this_uid]
    local code = block[#block]
    local name
    if code then
      name = code[0]
    end
    if name == "GOTO" then
      block[#block] = nil
      local label = code[1]
      block["goto"] = label
      g:add_edge(this_uid, labels[label])
    elseif name == "RETURN" then
      g:add_edge(this_uid, exit_uid)
    elseif name == "COND" then
      local then_eid = g:add_edge(this_uid, labels[code[3]])
      local else_eid = g:add_edge(this_uid, labels[code[4]])
      jumps[then_eid] = "THEN"
      jumps[else_eid] = "ELSE"
    else
      g:add_edge(this_uid, next_uid)
    end
    this_uid = next_uid
  end

  blocks.jumps = jumps
  return blocks
end

local function remove_unreachables(blocks, reachables)
  local g = blocks.g
  local u = g.u
  local u_after = u.after
  local uv = g.uv
  local uv_first = uv.first
  local uv_after = uv.after
  local vu = g.vu
  local vu_first = vu.first
  local vu_after = vu.after

  local uid = u.first
  while uid do
    local next_uid = u_after[uid]
    if not reachables[uid] then
      local eid = uv_first[uid]
      while eid do
        local next_eid = uv_after[eid]
        g:remove_edge(eid)
        eid = next_eid
      end
      local eid = vu_first[uid]
      while eid do
        local next_eid = vu_after[eid]
        g:remove_edge(eid)
        eid = next_eid
      end
      g:remove_vertex(uid)
      blocks[uid] = nil
    end
    uid = next_uid
  end

  return blocks
end

local function analyze_dominators(blocks, postorder)
  local g = blocks.g
  local entry_uid = blocks.entry_uid
  local vu = g.vu
  local vu_first = vu.first
  local vu_after = vu.after
  local vu_target = vu.target
  local n = #postorder

  local idom = g:find_dominators(entry_uid)

  for i = n, 1, -1 do
    local uid = postorder[i]
    local dom = {}
    local vid = uid
    while vid do
      dom[vid] = true
      vid = idom[vid]
    end
    blocks[uid].dom = dom
    blocks[uid].df = {}
  end

  for i = n, 1, -1 do
    local uid = postorder[i]
    local eid = vu_first[uid]
    if eid and vu_after[eid] then
      while eid do
        local vid = vu_target[eid]
        while vid ~= idom[uid] do
          blocks[vid].df[uid] = true
          vid = idom[vid]
        end
        eid = vu_after[eid]
      end
    end
  end

  return blocks
end

local function update_variables(variables, var, encoded_var, reference)
  local variable = variables[encoded_var]
  if not variable then
    variable = {
      key = var.key;
      index = var.index;
    }
    variables[encoded_var] = variable
  end
  if var.key == "U" or reference then
    variable.reference = true
  end
end

local function update_def(variables, def, var)
  local t = var.type
  if t == "value" or t == "array" then
    local encoded_var = var:encode_without_index()
    update_variables(variables, var, encoded_var)
    def[encoded_var] = true
  end
end

local function update_use(variables, def, use, var)
  local t = var.type
  if t == "value" or t == "array" then
    local encoded_var = var:encode_without_index()
    update_variables(variables, var, encoded_var)
    if not def[encoded_var] then
      use[encoded_var] = true
    end
  end
end

local function update_ref(variables, def, use, var)
  local t = var.type
  if t == "value" or t == "array" then
    local encoded_var = var:encode_without_index()
    update_variables(variables, var, encoded_var, true)
    if not def[encoded_var] then
      use[encoded_var] = true
    end
  end
end

local function analyze_variables(blocks, postorder)
  local variables = {}

  for i = #postorder, 1, -1 do
    local uid = postorder[i]
    local block = blocks[uid]
    local def = {}
    local use = {}

    for j = 1, #block do
      local code = block[j]
      local name = code[0]
      if name == "CLOSURE" then
        for k = 3, #code do
          update_ref(variables, def, use, code[k])
        end
        update_def(variables, def, code[1])
      elseif name == "RESULT" then
        for k = 1, #code do
          update_def(variables, def, code[k])
        end
      else
        for k = 2, #code do
          update_use(variables, def, use, code[k])
        end
        if name == "SETTABLE" or name == "CALL" or name == "RETURN" or name == "COND" then
          update_use(variables, def, use, code[1])
        else
          update_def(variables, def, code[1])
        end
      end
    end

    block.def = def
    block.use = use
  end

  blocks.variables = variables
  return blocks
end

local function analyze_liveness(blocks, postorder)
  local g = blocks.g
  local uv = g.uv
  local uv_first = uv.first
  local uv_after = uv.after
  local uv_target = uv.target
  local n = #postorder

  for i = n, 1, -1 do
    local uid = postorder[i]
    local block = blocks[uid]
    local use = block.use

    local live_in = {}
    for encoded_var in pairs(use) do
      live_in[encoded_var] = true
    end

    block.live_in = live_in
    block.live_out = {}
  end

  repeat
    local changed = false

    for i = n, 1, -1 do
      local uid = postorder[i]
      local block = blocks[uid]
      local def = block.def
      local use = block.use
      local live_in = block.live_in
      local live_out = block.live_out

      local eid = uv_first[uid]
      while eid do
        local vid = uv_target[eid]
        for encoded_var in pairs(blocks[vid].live_in) do
          if not live_out[encoded_var] then
            live_out[encoded_var] = true
            changed = true
          end
        end
        eid = uv_after[eid]
      end

      for encoded_var in pairs(live_out) do
        if not def[encoded_var] then
          if not live_in[encoded_var] then
            live_in[encoded_var] = true
            changed = true
          end
        end
      end
    end
  until not changed

  return blocks
end

local function resolve_variables(blocks)
  local g = blocks.g
  local u = g.u
  local u_first = u.first
  local u_after = u.after
  local variables = blocks.variables

  local uid = u_first
  while uid do
    local block = blocks[uid]
    for i = 1, #block do
      local code = block[i]
      local name = code[0]
      if name ~= "SETTABLE" and name ~= "RETURN" and name ~= "COND" then
        local var = code[1]
        local variable = variables[var:encode_without_index()]
        if variable and not variable.reference then
          local version = variable.version
          if version then
            code[1] = var[version]
            variable.version = version + 1
          else
            variable.version = 1
          end
        end
      end
    end
    uid = u_after[uid]
  end

  return blocks
end

return function (self)
  local blocks = resolve_jumps(generate(self.code_list))
  local g = blocks.g
  local entry_uid = blocks.entry_uid
  local uv_postorder, reachables = g:uv_postorder(entry_uid)
  remove_unreachables(blocks, reachables)
  analyze_dominators(blocks, uv_postorder)

  analyze_variables(blocks, uv_postorder)

  local vu_postorder = g:vu_postorder(blocks.exit_uid)
  analyze_liveness(blocks, vu_postorder)
  -- resolve_variables(blocks)
  self.blocks = blocks
  return self
end
