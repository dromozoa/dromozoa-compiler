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

local serializer = require "dromozoa.compiler.serializer"
local variable = require "dromozoa.compiler.variable"

local unpack = table.unpack or unpack

local templates = {
  MOVE     = serializer.template "%1 = %2";
  GETTABLE = serializer.template "%1 = gettable(%2, %3)";
  NEWTABLE = serializer.template "%1 = newtable()";
  ADD      = serializer.template "%1 = %2.checknumber() + %3.checknumber()";
  SUB      = serializer.template "%1 = %2.checknumber() - %3.checknumber()";
  MUL      = serializer.template "%1 = %2.checknumber() * %3.checknumber()";
  MOD      = serializer.template "%1 = std::fmod(%2.checknumber(), %3.checknumber())";
  POW      = serializer.template "%1 = std::pow(%2.checknumber(), %3.checknumber())";
  DIV      = serializer.template "%1 = %2.checknumber() / %3.checknumber()";
  IDIV     = serializer.template "%1 = std::floor(%2.checknumber() / %3.checknumber())";
  BAND     = serializer.template "%1 = %2.checkinteger() & %3.checkinteger()";
  BOR      = serializer.template "%1 = %2.checkinteger() | %3.checkinteger()";
  BXOR     = serializer.template "%1 = %2.checkinteger() ^ %3.checkinteger()";
  SHL      = serializer.template "%1 = %2.checkinteger() << %3.checkinteger()";
  SHR      = serializer.template "%1 = %2.checkinteger() >> %3.checkinteger()";
  UNM      = serializer.template "%1 = -%2.checknumber()";
  BNOT     = serializer.template "%1 = ~%2.checkinteger()";
  NOT      = serializer.template "%1 = !%2.toboolean()";
  LEN      = serializer.template "%1 = len(%2)";
  CONCAT   = serializer.template "%1 = %2.checkstring() + %3.checkstring()";
  EQ       = serializer.template "%1 = eq(%2, %3)";
  NE       = serializer.template "%1 = !eq(%2, %3)";
  LT       = serializer.template "%1 = lt(%2, %3)";
  LE       = serializer.template "%1 = le(%2, %3)";
  TONUMBER = serializer.template "%1 = %2.checknumber()";
}

local char_table = {
  ["\""] = [[\"]];
  ["\\"] = [[\\]];
  ["\n"] = [[\n]];
}

for byte = 0x00, 0x7F do
  local char = string.char(byte)
  if not char_table[char] then
    char_table[char] = ([[\x02X]]):format(byte)
  end
end

local function encode_string(s)
  local s = s:gsub("[%z\1-\31\127]", char_table)
  return "\"" .. s .. "\""
end

local function generate_declations(out, proto_name, blocks, postorder)
  for i = #postorder, 1, -1 do
    local uid = postorder[i]
    out:write(serializer.template "std::shared_ptr<thunk_t> %1_%2(%3);\n" (
      proto_name,
      uid,
      serializer.entries(blocks[uid].params)
        :map(function (encoded_var, param)
          local var = param[0]
          if var.reference then
            return serializer.tuple("ref_t", var)
          elseif var.type == "array" then
            return serializer.tuple("array_t", var)
          else
            return serializer.tuple("var_t", var)
          end
        end)
        :sort(function (a, b) return a[2] < b[2] end)
        :unshift(
          serializer.tuple("continuation_t", "k"),
          serializer.tuple("state_t", "state"))
        :map(serializer.template "%1 %2")
        :separated ", "
    ))
  end
end

local function generate_definitions(out, proto_name, blocks, postorder)
  local g = blocks.g
  local uv = g.uv
  local uv_first = uv.first
  local uv_target = uv.target

  for i = #postorder, 1, -1 do
    local uid = postorder[i]
    local block = blocks[uid]

    out:write(serializer.template "static std::shared_ptr<thunk_t> %1_%2(%3) {\n" (
      proto_name,
      uid,
      serializer.entries(block.params)
        :map(function (encoded_var, param)
          local var = param[0]
          if var.reference then
            return serializer.tuple("ref_t", var)
          elseif var.type == "array" then
            return serializer.tuple("array_t", var)
          else
            return serializer.tuple("var_t", var)
          end
        end)
        :sort(function (a, b) return a[2] < b[2] end)
        :unshift(
          serializer.tuple("continuation_t", "k"),
          serializer.tuple("state_t", "state"))
        :map(serializer.template "%1 %2")
        :separated ", "
    ))

    for j = 1, #block do
      local code = block[j]
      local name = code[0]

      if name == "GETTABLE" then
        local vid = uv_target[uv_first[uid]]
        out:write(serializer.template "  return %1->gettable([=](state_t state, array_t args) {\n" (code[2]))

        local var = code[1]
        if var.declare then
          out:write(serializer.template "    %1 %2 { args[0] };\n" (var.reference and "ref_t" or "var_t", var))
        else
          out:write(serializer.template "    *%1 = args[0];\n" (var))
        end

        out:write(serializer.template [[
    return %1_%2(%3);
  }, state, *%4);
]] (
          proto_name,
          vid,
          serializer.entries(blocks[vid].params)
            :map(function (encoded_var, param)
              return param[0]
            end)
            :sort()
            :unshift("k", "state")
            :separated ", ",
          code[3]
        ))
      elseif name == "RESULT" then
        local call = block[j - 1]
        local vid = uv_target[uv_first[uid]]
        out:write(serializer.template "  return %1->call([=](state_t state, array_t args) {\n" (call[1]))

        -- TODO handle array_t
        for k = 1, #code do
          local var = code[k]
          if var.declare then
            out:write(serializer.template "    %1 %2 { args[%3] };\n" (var.reference and "ref_t" or "var_t", var, k - 1))
          else
            out:write(serializer.template "    *%1 = args[%2];\n" (var, k - 1))
          end
        end

        out:write(serializer.template [[
    return %1_%2(%3);
  }, state, {%4});
]](
          proto_name,
          vid,
          serializer.entries(blocks[vid].params)
            :map(function (encoded_var, param)
              return param[0]
            end)
            :sort()
            :unshift("k", "state")
            :separated ", ",
          serializer.sequence(call, 2)
            :map(serializer.template "*%1")
            :if_not_empty(" ", " ")
            :separated ", "
        ))
      end
    end

    if block.entry then
      local vid = uv_target[uv_first[uid]]
      out:write(serializer.template [[
  return %1_%2(%3);
]](
        proto_name,
        vid,
        serializer.entries(blocks[vid].params)
          :map(function (encoded_var, param)
            return param[0]
          end)
          :sort()
          :unshift("k", "state")
          :separated ", "
      ))
    end

    if block.exit then
      out:write(serializer.template [[
  return k(state, {});
]]())
    end

    out:write "}\n"
  end
end


local function generate_closure(out, self, postorder)
  local constants = self.constants
  local upvalues = self.upvalues
  local blocks = self.blocks
  local entry_uid = blocks.entry_uid
  local entry_params = blocks[entry_uid].params

  out:write(serializer.template [[
class %1 : public function_t {
public:
  %1(%2)%3 {}
  std::shared_ptr<thunk_t> operator()(continuation_t k, state_t state, array_t args) {
%4%
    return %1_%5(%6);
  }
private:
]] (
    self[1],
    serializer.sequence(upvalues)
      :map(function (item) return item[1] end)
      :map(serializer.template "ref_t %1")
      :separated ", ",
    serializer.sequence(upvalues)
      :map(function (item) return item[1] end)
      :map(serializer.template "%1(%1)")
      :if_not_empty " : "
      :separated ", ",
    serializer.entries(entry_params)
      :map(function (encoded_var, param)
        local var = param[0]
        local key = var.key
        if key == "A" then
          if var.reference then
            return serializer.tuple("ref_t", var, "[" .. var.number .. "]")
          else
            return serializer.tuple("var_t", var, "[" .. var.number .. "]")
          end
        elseif key == "V" then
          return serializer.tuple("array_t", var, ".slice(" .. self.A .. ")")
        end
      end)
      :sort(function (a, b) return a[2] < b[2] end)
      :map(serializer.template "    %1 %2 = args%3;\n"),
    entry_uid,
    serializer.entries(entry_params)
      :map(function (encoded_var, param)
        return param[0]
      end)
      :sort()
      :unshift("k", "state")
      :separated ", "
  ))

  generate_definitions(out, self[1], blocks, postorder)

  out:write(serializer.template [[
%1%
%2%
};
%3%
]] (
    serializer.sequence(upvalues)
      :map(function (item) return item[1] end)
      :map(serializer.template "  ref_t %1;\n"),
    serializer.sequence(constants)
      :map(function (item) return item[1] end)
      :map(serializer.template "  static const var_t %1;\n"),
    serializer.sequence(constants)
      :map(function (item)
        if item.type == "string" then
          return serializer.tuple(self[1], item[1], encode_string(item.source))
        else
          return serializer.tuple(self[1], item[1], ("%.17g"):format(tonumber(item.source)))
        end
      end)
      :map(serializer.template "const var_t %1::%2 { %3 };\n")
  ))
end

return function (self, out)
  local blocks = self.blocks
  local g = blocks.g
  local uv_postorder = g:uv_postorder(blocks.entry_uid)
  generate_closure(out, self, uv_postorder)
  return out
end
