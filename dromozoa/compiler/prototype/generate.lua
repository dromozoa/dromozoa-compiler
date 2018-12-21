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

local not_split = {
  MOVE     = true;
  NEWTABLE = true;
  NOT      = true;
  CALL     = true;
  CLOSURE  = true;
  TONUMBER = true;
}

local not_assign = {
  SETTABLE = true;
  CALL     = true;
  RETURN   = true;
  COND     = true;
}

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
      if not not_split[name] then
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
      local then_eid = g:add_edge(this_uid, labels[code[2]])
      local else_eid = g:add_edge(this_uid, labels[code[3]])
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
  local dom_child = {}
  local df = {}

  for i = n, 1, -1 do
    local uid = postorder[i]
    dom_child[uid] = {}
    df[uid] = {}
  end

  for i = n, 1, -1 do
    local uid = postorder[i]
    local dom = idom[uid]
    if dom then
      local uids = dom_child[dom]
      uids[#uids + 1] = uid
      local eid = vu_first[uid]
      if eid and vu_after[eid] then
        while eid do
          local vid = vu_target[eid]
          while vid ~= dom do
            df[vid][uid] = true
            vid = idom[vid]
          end
          eid = vu_after[eid]
        end
      end
    end
  end

  return idom, dom_child, df
end

local function analyze_liveness_def(def, var)
  local t = var.type
  if t == "value" or t == "array" then
    local encoded_var = var:encode_without_index()
    def[encoded_var] = true
  end
end

local function analyze_liveness_use(def, use, var)
  local t = var.type
  if t == "value" or t == "array" then
    local encoded_var = var:encode_without_index()
    if not def[encoded_var] then
      use[encoded_var] = true
    end
  end
end

local function analyze_liveness(blocks, postorder)
  local g = blocks.g
  local uv = g.uv
  local uv_first = uv.first
  local uv_after = uv.after
  local uv_target = uv.target
  local n = #postorder

  local defs = {}
  local uses = {}
  local lives_in = {}
  local lives_out = {}

  for i = n, 1, -1 do
    local uid = postorder[i]
    local block = blocks[uid]
    local def = {}
    local use = {}

    for j = 1, #block do
      local code = block[j]
      local name = code[0]
      if name == "RESULT" then
        for k = 1, #code do
          analyze_liveness_def(def, code[k])
        end
      else
        for k = 2, #code do
          analyze_liveness_use(def, use, code[k])
        end
        if not_assign[name] then
          analyze_liveness_use(def, use, code[1])
        else
          analyze_liveness_def(def, code[1])
        end
      end
    end

    local live_in = {}
    for encoded_var in pairs(use) do
      live_in[encoded_var] = true
    end

    defs[uid] = def
    uses[uid] = use
    lives_in[uid] = live_in
    lives_out[uid] = {}
  end

  repeat
    local changed = false

    for i = n, 1, -1 do
      local uid = postorder[i]
      local def = defs[uid]
      local use = uses[uid]
      local live_in = lives_in[uid]
      local live_out = lives_out[uid]

      local eid = uv_first[uid]
      while eid do
        local vid = uv_target[eid]
        for encoded_var in pairs(lives_in[vid]) do
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

  return lives_in, lives_out
end

local function resolve_variables_def(defs, refs, uid, var, encoded_var)
  local t = var.type
  if t == "value" or t == "array" then
    if not encoded_var then
      encoded_var = var:encode_without_index()
    end
    local def = defs[encoded_var]
    if def then
      def[#def + 1] = uid
    else
      defs[encoded_var] = { uid }
    end
    if var.key == "U" then
      refs[encoded_var] = true
    end
  end
end

local function resolve_variables(blocks, lives_in, postorder)
  local entry_uid = blocks.entry_uid

  local refs = {}
  local defs = {}

  for encoded_var in pairs(lives_in[entry_uid]) do
    resolve_variables_def(defs, refs, entry_uid, variable.decode(encoded_var), encoded_var)
  end

  for i = #postorder, 1, -1 do
    local uid = postorder[i]
    local block = blocks[uid]
    for j = 1, #block do
      local code = block[j]
      local name = code[0]
      if name == "CLOSURE" then
        resolve_variables_def(defs, refs, uid, code[1])
        for k = 3, #code do
          refs[code[k]:encode_without_index()] = true
        end
      elseif name == "RESULT" then
        for k = 1, #code do
          resolve_variables_def(defs, refs, uid, code[k])
        end
      elseif not not_assign[name] then
        resolve_variables_def(defs, refs, uid, code[1])
      end
    end

    local params = {}
    for encoded_var in pairs(lives_in[uid]) do
      params[encoded_var] = true
    end
    block.params = params
  end

  local vers = {}
  for encoded_var, def in pairs(defs) do
    if #def > 1 and not refs[encoded_var] then
      vers[encoded_var] = 0
    end
  end

  return defs, refs, vers
end

local function insert_phi_functions(blocks, df, defs, vers, postorder)
  for encoded_var in pairs(vers) do
    local def = defs[encoded_var]

    local inserted = {}
    local color = {}
    local stack = {}

    for i = 1, #def do
      local uid = def[i]
      color[uid] = true
      stack[#stack + 1] = uid
    end

    while true do
      local n = #stack
      if n == 0 then
        break
      end
      local uid = stack[n]
      stack[n] = nil

      for vid in pairs(df[uid]) do
        if not inserted[vid] then
          local params = blocks[vid].params
          if params[encoded_var] then
            params[encoded_var] = { phi = true }
            inserted[vid] = true
          end
          if not color[vid] then
            color[vid] = true
            stack[#stack + 1] = vid
          end
        end
      end
    end
  end
end

local function rename_variables_def(vers, stacks, code, i)
  local var = code[i]
  local encoded_var = var:encode_without_index()
  local stack = stacks[encoded_var]
  if stack then
    local v = vers[encoded_var]
    vers[encoded_var] = v + 1
    stack[#stack + 1] = v
    code[i] = var[v]
  end
end

local function rename_variables_use(stacks, code, i)
  local var = code[i]
  local stack = stacks[var:encode_without_index()]
  if stack then
    code[i] = var[stack[#stack]]
  end
end

local function rename_variables_pop(stacks, var, code)
  local stack = stacks[var:encode_without_index()]
  if stack then
    stack[#stack] = nil
  end
end

local function rename_variables_search(blocks, dom_child, vers, stacks, uid)
  local g = blocks.g
  local uv = g.uv
  local uv_after = uv.after
  local uv_target = uv.target
  local block = blocks[uid]
  local n = #block

  local params = block.params
  for encoded_var, param in pairs(params) do
    local stack = stacks[encoded_var]
    if stack then
      if param == true then
        params[encoded_var] = { [0] = variable.decode(encoded_var)[stack[#stack]] }
      else
        assert(param.phi)
        local v = vers[encoded_var]
        vers[encoded_var] = v + 1
        stack[#stack + 1] = v
        param[0] = variable.decode(encoded_var)[v]
      end
    end
  end

  for i = 1, n do
    local code = block[i]
    local name = code[0]
    if name == "RESULT" then
      for j = 1, #code do
        rename_variables_def(vers, stacks, code, j)
      end
    else
      for j = 2, #code do
        rename_variables_use(stacks, code, j)
      end
      if not_assign[name] then
        rename_variables_use(stacks, code, 1)
      else
        rename_variables_def(vers, stacks, code, 1)
      end
    end
  end

  local eid = uv.first[uid]
  while eid do
    local vid = uv_target[eid]
    for encoded_var, param in pairs(blocks[vid].params) do
      if type(param) == "table" and param.phi then
        local stack = stacks[encoded_var]
        param[#param + 1] = variable.decode(encoded_var)[stack[#stack]]
      end
    end
    eid = uv_after[eid]
  end

  local uids = dom_child[uid]
  for i = 1, #uids do
    rename_variables_search(blocks, dom_child, vers, stacks, uids[i])
  end

  for i = 1, n do
    local code = block[i]
    local name = code[0]
    if name == "RESULT" then
      for j = 1, #code do
        rename_variables_pop(stacks, code[j], code)
      end
    elseif not not_assign[name] then
      rename_variables_pop(stacks, code[1], code)
    end
  end
end

local function rename_variables(blocks, dom_child, vers)
  local stacks = {}
  for encoded_var in pairs(vers) do
    stacks[encoded_var] = { 0 }
  end
  rename_variables_search(blocks, dom_child, vers, stacks, blocks.entry_uid)
end

local function resolve_types(blocks, refs, postorder)
  for i = #postorder, 1, -1 do
    local uid = postorder[i]
    local block = blocks[uid]
    local params = block.params

    for encoded_var, param in pairs(params) do
      if param == true then
        local var = variable.decode(encoded_var)
        if refs[encoded_var] then
          var.reference = true
        end
        params[encoded_var] = { [0] = var }
      else
        if refs[encoded_var] then
          param[0].reference = true
        end
      end
    end

    for j = 1, #block do
      local code = block[j]
      local name = code[0]
      if name == "RESULT" then
        for k = 1, #code do
          local var = code[k]
          if not params[var:encode_without_index()] then
            var.declare = true
          end
        end
      elseif not not_assign[name] then
        local var = code[1]
        if not params[var:encode_without_index()] then
          var.declare = true
        end
      end
      for k = 1, #code do
        local var = code[k]
        if refs[var:encode_without_index()] then
          var.reference = true
        end
      end
    end
  end
end

return function (self)
  local blocks = resolve_jumps(generate(self.code_list))
  local g = blocks.g
  local uv_postorder, reachables = g:uv_postorder(blocks.entry_uid)
  remove_unreachables(blocks, reachables)
  local idom, dom_child, df = analyze_dominators(blocks, uv_postorder)
  local lives_in = analyze_liveness(blocks, g:vu_postorder(blocks.exit_uid))
  local defs, refs, vers = resolve_variables(blocks, lives_in, uv_postorder)
  insert_phi_functions(blocks, df, defs, vers, uv_postorder)
  rename_variables(blocks, dom_child, vers)
  resolve_types(blocks, refs, uv_postorder)
  self.blocks = blocks
  return self
end
