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

local function generate(proto)
  local flat_code = proto.flat_code
  local n = #flat_code

  local g = graph()
  local u = g.u
  local u_after = u.after

  local entry_uid = g:add_vertex()
  local uid
  local uids = { entry_uid }
  local block
  local blocks = { [entry_uid] = {} }
  local labels = {}

  for i = 1, n do
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
  local jumps = {}

  local this_uid = u.first
  local next_uid = u_after[this_uid]
  while next_uid do
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
    next_uid = u_after[this_uid]
  end

  local uid = u.first
  while uid do
    local block = blocks[uid]
    local uses = {}
    local defs = {}
    for j = 1, #block do
      local code = block[j]
      local name = code[0]
      if name == "SETTABLE" then
        uses[code[1]] = true
        uses[code[2]] = true
        uses[code[3]] = true
      elseif name == "CALL" then
        local var = code[1]
        if var ~= "NIL" then
          defs[var] = true
        end
        for k = 2, #code do
          uses[code[k]] = true
        end
      elseif name == "RETURN" then
        for k = 1, #code do
          uses[code[k]] = true
        end
      elseif name == "SETLIST" then
        uses[code[1]] = true
        uses[code[3]] = true
      elseif name == "CLOSURE" then
        defs[code[1]] = true
      elseif name == "COND" then
        uses[code[1]] = true
      else
        defs[code[1]] = true
        for k = 2, #code do
          uses[code[k]] = true
        end
      end
    end
    block.uses = uses
    block.defs = defs
    uid = u_after[uid]
  end

  -- for i = 1, n do
  --   local block = blocks[uids[i]]
  --   for j = 1, #block do
  --     local code = block[j]
  --     local name = code[0]
  --     if name == "SETTABLE" then
  --     elseif name == "RETURN" then
  --     elseif name == "COND" then
  --     elseif name == "SETLIST" then
  --     else
  --       for k = 2, #code do
  --       end
  --     end
  --   end
  -- end

  -- TODO investigate
  -- uses
  -- defs
  -- use-after-defs???
  -- only

  proto.basic_blocks = {
    g = g;
    entry_uid = entry_uid;
    exit_uid = exit_uid;
    blocks = blocks;
    jumps = jumps;
  }
end

return function (self)
  local protos = self.protos
  for i = 1, #protos do
    generate(protos[i])
  end
  return self
end
