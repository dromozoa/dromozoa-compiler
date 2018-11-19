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

local function generate_basic_blocks(code_list)
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
      if name == "CALL" or name == "RETURN" or name == "GOTO" or name == "COND" then
        uid = nil
      end
    end
  end

  local exit_uid = g:add_vertex()
  uids[#uids + 1] = exit_uid
  blocks[exit_uid] = { exit = true }

  return {
    g = g;
    entry_uid = entry_uid;
    exit_uid = exit_uid;
    blocks = blocks;
  }, uids, labels
end

local function resolve(bb, uids, labels)
  local g = bb.g
  local exit_uid = bb.exit_uid
  local blocks = bb.blocks

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

  bb.jumps = jumps
  return bb
end

local function analyze_dominator(bb)
  local g = bb.g
  local u = g.u
  local u_first = u.first
  local u_after = u.after
  local vu = g.vu
  local vu_first = vu.first
  local vu_after = vu.after
  local vu_target = vu.target
  local entry_uid = bb.entry_uid
  local blocks = bb.blocks

  local all = {}

  local uid = u_first
  while uid do
    all[#all + 1] = uid
    uid = u_after[uid]
  end

  local uid = u_first
  while uid do
    local block = blocks[uid]
    if uid == entry_uid then
      block.dom = { [uid] = true }
    else
      local dom = {}
      for i = 1, #all do
        dom[all[i]] = true
      end
      block.dom = dom
    end
    block.df = {}
    uid = u_after[uid]
  end

  repeat
    local changed = false

    local uid = u_first
    while uid do
      local block = blocks[uid]
      local dom = block.dom
      local set

      local eid = vu_first[uid]
      while eid do
        local vid = vu_target[eid]
        local pred_dom = blocks[vid].dom
        if set then
          for wid in pairs(set) do
            if not pred_dom[wid] then
              set[wid] = nil
            end
          end
        else
          set = {}
          for wid in pairs(pred_dom) do
            set[wid] = true
          end
        end
        eid = vu_after[eid]
      end
      if set then
        set[uid] = true
      else
        set = { [uid] = true }
      end

      if not changed then
        for vid in pairs(set) do
          if not dom[vid] then
            changed = true
            break
          end
        end
      end

      if not changed then
        for vid in pairs(dom) do
          if not set[vid] then
            changed = true
            break
          end
        end
      end

      block.dom = set
      uid = u_after[uid]
    end
  until not changed

  local uid = u_first
  while uid do
    local dom = blocks[uid].dom
    local eid = vu_first[uid]
    if eid and vu_after[eid] then
      while eid do
        local vid = vu_target[eid]
        for wid in pairs(blocks[vid].dom) do
          if not (dom[wid] and uid ~= wid) then
            blocks[wid].df[uid] = true
          end
        end
        eid = vu_after[eid]
      end
    end
    uid = u_after[uid]
  end

  return bb
end

local function update_def(def, var)
  local t = var.type
  if t == "value" or t == "array" then
    def[var:encode_without_index()] = true
  end
end

local function update_use(def, use, var)
  local t = var.type
  if t == "value" or t == "array" then
    local encoded_var = var:encode_without_index()
    if not def[encoded_var] then
      use[encoded_var] = true
    end
  end
end

local function analyze_liveness(bb)
  local g = bb.g
  local u = g.u
  local u_first = u.first
  local u_after = u.after
  local uv = g.uv
  local uv_first = uv.first
  local uv_after = uv.after
  local uv_target = uv.target
  local blocks = bb.blocks

  local varmap = {}

  local uid = u_first
  while uid do
    local block = blocks[uid]
    local def = {}
    local use = {}
    for i = 1, #block do
      local code = block[i]
      local name = code[0]
      if name == "CLOSURE" then
        local upvalues = code[2].proto.upvalues
        for i = 1, #upvalues do
          update_use(def, use, upvalues[i][2])
        end
        update_def(def, code[1])
      else
        for i = 2, #code do
          update_use(def, use, code[i])
        end
        if name == "SETTABLE" or name == "RETURN" or name == "SETLIST" or name == "COND" then
          update_use(def, use, code[1])
        else
          update_def(def, code[1])
        end
      end
    end

    local live_in = {}
    for encoded_var in pairs(use) do
      live_in[encoded_var] = true
    end

    block.def = def
    block.use = use
    block.live_in = live_in
    block.live_out = {}
    uid = u_after[uid]
  end

  repeat
    local changed = false

    local uid = u_first
    while uid do
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

      uid = u_after[uid]
    end
  until not changed

  return bb
end

local function ssa(bb)
  local g = bb.g
  local u = g.u
  local u_first = u.first
  local u_after = u.after
  local blocks = bb.blocks

  local varmap = {}

  local uid = u_first
  while uid do
    local block = blocks[uid]
    for i = 1, #block do
      local code = block[i]
    end
    uid = u_after[uid]
  end

  return bb
end

return function (self)
  local bb = resolve(generate_basic_blocks(self.code_list))
  analyze_dominator(bb)
  analyze_liveness(bb)
  -- ssa(bb)
  self.bb = bb
  return self
end