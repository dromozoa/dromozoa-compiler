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

local function split(code_block)
  local g = graph()
  local entry_uid = g:add_vertex()
  local uid
  local uids = { entry_uid }
  local block
  local blocks = { [entry_uid] = { entry = true } }
  local labels = {}

  for i = 1, #code_block do
    local code = code_block[i]
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

local function update_varmap(varmap, key, uid, var)
  local t = var.type
  if t == "upvalue" or t == "value" or t == "array" then
    local encoded_var = var:encode_without_index()
    local map = varmap[encoded_var]
    if not map then
      map = {}
      varmap[encoded_var] = map
    end
    local uids = map[key]
    if uids then
      local n = #uids
      if uids[n] ~= uid then
        uids[n + 1] = uid
      end
    else
      map[key] = { uid }
    end
  end
end

local function analyze(bb)
  local g = bb.g
  local u = g.u
  local u_after = u.after
  local blocks = bb.blocks

  local varmap = {}

  local uid = u.first
  while uid do
    local block = blocks[uid]
    local ref = {}
    local def = {}
    local use = {}
    for i = 1, #block do
      local code = block[i]
      local name = code[0]
      if name == "CLOSURE" then
        update_varmap(varmap, "def", uid, code[1])
        local upvalues = code[2].proto.upvalues
        for j = 1, #upvalues do
          update_varmap(varmap, "ref", uid, upvalues[j][2])
        end
      else
        if name == "SETTABLE" or name == "RETURN" or name == "SETLIST" or name == "COND" then
          update_varmap(varmap, "use", uid, code[1])
        else
          update_varmap(varmap, "def", uid, code[1])
        end
        for i = 2, #code do
          update_varmap(varmap, "use", uid, code[i])
        end
      end
    end
    uid = u_after[uid]
  end

  bb.varmap = varmap
  return bb
end

return function (self)
  local bb = resolve(split(self.code))
  analyze(bb)
  self.bb = bb
  return self
end