-- Copyright (C) 2019 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local serializer = require "dromozoa.compiler.serializer"
local variable = require "dromozoa.compiler.variable"

local _ = serializer.template

local char_table = {
  ["\""] = [[\"]]; -- 34
  ["\\"] = [[\\]]; -- 92
  ["\a"] = [[\a]];
  ["\b"] = [[\b]];
  ["\f"] = [[\f]];
  ["\n"] = [[\n]];
  ["\r"] = [[\r]];
  ["\t"] = [[\t]];
  ["\v"] = [[\v]];
}

for byte = 0x00, 0x7F do
  local char = string.char(byte)
  if not char_table[char] then
    char_table[char] = ([[\03d]]):format(byte)
  end
end

local function encode_string(s)
  local s = s:gsub("[%z\1-\31\34\92\127]", char_table)
  return "\"" .. s .. "\""
end

local function encode_number(source)
  return ("%.17g"):format(assert(tonumber(source)))
end

local function encode_assign_var(var)
  if var.reference then
    return ("%s[1]"):format(var:encode_without_index())
  elseif var.declare then
    return ("local %s"):format(var:encode_without_index())
  else
    return ("%s"):format(var:encode_without_index())
  end
end

local function encode_var(var)
  if var.reference then
    return ("%s[1]"):format(var:encode_without_index())
  elseif var.type == "array" then
    return ("%s"):format(var:encode())
  elseif var.key == "K" then
    return ("self.%s"):format(var:encode())
  else
    return ("%s"):format(var:encode_without_index())
  end
end

local templates = {
  MOVE         = _"$1 = $2";
  GETTABLE     = _"$1 = $2[$3]";
  NEWTABLE     = _"$1 = {}";
  ADD          = _"$1 = $2 + $3";
  CONCAT       = _"$1 = $2 .. $3";
  EQ           = _"$1 = $2 == $3";
  TYPE         = _"$1 = TYPE($2)";
  TYPENAME     = _"$1 = TYPENAME($2)";
  TONUMBER     = _"$1 = tonumber($2)";
  GETMETAFIELD = _"$1 = GETMETAFIELD($2, $3)";
}

local function generate_proto(out, self)
  out:write(serializer.template [[
local $1 = {
$2$
}
]] {
    self[1];
    serializer.sequence(self.constants)
      :map(function (item)
        if item.type == "string" then
          return { item[1], encode_string(item.source) }
        else
          return { item[1], encode_number(item.source) }
        end
      end)
      :map "  $1 = $2;\n";
  })
end

local function generate_closure(out, self)
  local upvalues = self.upvalues
  local blocks = self.blocks

  out:write(serializer.template [[
$1.closure = function ($2)
  return {
    __index = $1;
$3$
  }
end
]] {
    self[1];
    serializer.sequence(upvalues)
      :map(function (item)
        return item[1]
      end)
      :separated ", ";
    serializer.sequence(upvalues)
      :map(function (item)
        return item[1]
      end)
      :map "    $0 = $0;\n";
  })
end

local function generate_call(out, self)
  local blocks = self.blocks
  local entry_uid = blocks.entry_uid

  local params = serializer.sequence(self.names)
    :map(function (item)
      local var = item[1]
      if var.key == "A" then
        return var
      end
    end)
    :sort()
  if self.vararg then
    params[#params + 1] = "..."
  end

  out:write(serializer.template [[
function $1:call($2)
$3$
$4$
  return self:b$5($6)
end
]] {
    self[1];
    params
      :unshift("cont", "catch", "coro")
      :separated ", ";
    serializer.entries(blocks.refs)
      :map(function (encoded_var)
        return variable.decode(encoded_var)
      end)
      :sort()
      :map(function (var)
        if var.key == "U" then
          return { var, "self.", "" }
        else
          return { var, "" }
        end
      end)
      :map "  local $1 = ref($2$1)\n";
    self.vararg
      and "  local V0 = vararg(...)\n"
      or "";
    entry_uid;
    serializer.entries(blocks[entry_uid].params)
      :map(function (_, param)
        return param[0]:encode_without_index()
      end)
      :sort()
      :unshift("cont", "catch", "coro")
      :separated ", "
  })
end

local function generate_block(out, self, uid)
  local blocks = self.blocks
  local g = blocks.g
  local uv = g.uv
  local uv_after = uv.after
  local uv_target = uv.target
  local block = assert(blocks[uid])

  local succ = {}
  local eid = uv.first[uid]
  while eid do
    succ[#succ + 1] = uv_target[eid]
    eid = uv_after[eid]
  end

  out:write(serializer.template [[
function $1:b$2($3)
]] {
    self[1];
    uid;
    serializer.entries(block.params)
      :map(function (_, param)
        return param[0]:encode_without_index()
      end)
      :sort()
      :unshift("cont", "catch", "coro")
      :separated ", "
  })

  for i = 1, #block do
    local code = block[i]
    local name = code[0]

    if name == "SETTABLE" then
      out:write(serializer.template "  $1[$2] = $3\n" {
        encode_var(code[1]);
        encode_var(code[2]);
        encode_var(code[3]);
      })
    elseif name == "CALL" then
      -- noop
    elseif name == "RESULT" then
    elseif name == "RETURN" then
    elseif name == "COND" then
      local vid = assert(succ[1])
      local wid = assert(succ[2])
      succ = nil
      out:write(serializer.template [[
  if $1 then
    return self:b$2($3)
  else
    return self:b$4($5)
  end
]] {
        code[1];
        vid;
        serializer.entries(blocks[vid].params)
          :map(function (_, param)
            return param[0]:encode_without_index()
          end)
          :sort()
          :unshift("cont", "catch", "coro")
          :separated ", ";
        wid;
        serializer.entries(blocks[wid].params)
          :map(function (_, param)
            return param[0]:encode_without_index()
          end)
          :sort()
          :unshift("cont", "catch", "coro")
          :separated ", ";
      })

    elseif name == "ERROR" then
      succ = nil
      out:write(serializer.template [[
  return catch($1, $2)
]] {
        code[1];
        code[2];
      })
    else
      local tmpl = templates[name]
      local data = { encode_assign_var(code[1]) }
      for j = 2, #code do
        -- print(name, j, code[j])
        data[j] = encode_var(code[j])
      end
      if tmpl then
        out:write("  ", tmpl(data), "\n")
      else
        out:write("--", name, "\n")
      end
    end
  end

  if succ and not block.exit then
    local vid = assert(succ[1])
    out:write(serializer.template [[
  return self:b$1($2)
]] {
      vid;
      serializer.entries(blocks[vid].params)
        :map(function (_, param)
          return param[0]:encode_without_index()
        end)
        :sort()
        :unshift("cont", "catch", "coro")
        :separated ", "
    })
  end

  out:write "end\n"
end

local function generate_blocks(out, self)
  local blocks = self.blocks
  local g = blocks.g
  local u = g.u
  local u_after = u.after

  local uid = u.first
  while uid do
    generate_block(out, self, uid)
    uid = u_after[uid]
  end
end

return function (self, out)
  generate_proto(out, self)
  generate_closure(out, self)
  generate_call(out, self)
  generate_blocks(out, self)
  return out
end
