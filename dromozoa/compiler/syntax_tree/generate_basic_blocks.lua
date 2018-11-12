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

local ignore_table = {
  NIL = true;
  FALSE = true;
  TRUE = true;
  K = true;
}

local function update_useset(useset, code, i)
  local var = code[i]
  local key, i = decode_var(var)
  if not ignore_table[key] then
    if key == "V" or key == "T" then
      useset[key] = true
    else
      useset[var] = true
    end
  end
end

local function update_usemap(usemap, useset, uid)
  local use = {}
  for var in pairs(useset) do
    use[#use + 1] = var
    local uids = usemap[var]
    if uids then
      uids[#uids + 1] = uid
    else
      usemap[var] = { uid }
    end
  end
  table.sort(use)
  return use
end

local function split(proto)
  local flat_code = proto.flat_code

  local g = graph()
  local entry_uid = g:add_vertex()
  local uids = { entry_uid }
  local uid
  local block
  local blocks = { [entry_uid] = {} }
  local labels = {}

  for i = 1, #flat_code do
    local code = flat_code[i]
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
  blocks[exit_uid] = {}

  return {
    g = g;
    entry_uid = entry_uid;
    exit_uid = exit_uid;
    blocks = blocks;
  }, uids, labels
end

local function resolve(basic_blocks, uids, labels)
  local g = basic_blocks.g
  local exit_uid = basic_blocks.exit_uid
  local blocks = basic_blocks.blocks

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

  basic_blocks.jumps = jumps
  return basic_blocks
end

local function analyze(basic_blocks)
  local g = basic_blocks.g
  local u = g.u
  local u_after = u.after
  local entry_uid = basic_blocks.entry_uid
  local exit_uid = basic_blocks.exit_uid
  local blocks = basic_blocks.blocks

  local defmap = {}
  local usemap = {}

  local uid = u.first
  while uid do
    local block = blocks[uid]
    local defset = {}
    local useset = {}
    for j = 1, #block do
      local code = block[j]
      local name = code[0]
      if name == "SETTABLE" then
        update_useset(useset, code, 1)
        update_useset(useset, code, 2)
        update_useset(useset, code, 3)
      elseif name == "CALL" then
        update_useset(defset, code, 1)
        for k = 2, #code do
          update_useset(useset, code, k)
        end
      elseif name == "RETURN" then
        for k = 1, #code do
          update_useset(useset, code, k)
        end
      elseif name == "SETLIST" then
        update_useset(useset, code, 1)
        update_useset(useset, code, 3)
      elseif name == "CLOSURE" then
        update_useset(defset, code, 1)
      elseif name == "COND" then
        update_useset(useset, code, 1)
      else
        update_useset(defset, code, 1)
        for k = 2, #code do
          update_useset(useset, code, k)
        end
      end
    end

    block.defset = defset
    block.useset = useset
    block.def = update_usemap(defmap, defset, uid)
    block.use = update_usemap(usemap, useset, uid)

    uid = u_after[uid]
  end

  basic_blocks.defmap = defmap
  basic_blocks.usemap = usemap
  return basic_blocks
end

local function generate(proto)
  local basic_blocks = resolve(split(proto))
  -- analyze(basic_blocks)
  proto.basic_blocks = basic_blocks
end

return function (self)
  local protos = self.protos
  for i = 1, #protos do
    generate(protos[i])
  end
  return self
end
