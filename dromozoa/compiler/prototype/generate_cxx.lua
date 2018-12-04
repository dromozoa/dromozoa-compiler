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

local function generate_declations(out, proto_name, blocks, postorder)
  for i = #postorder, 1, -1 do
    local uid = postorder[i]
    out:write(serializer.template "std::function<void()> %1_%2(%3);\n" (
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
            return serializer.tuple("value_t", var)
          end
        end)
        :sort(function (a, b) return a[2] < b[2] end)
        :unshift(
          serializer.tuple("std::shared_ptr<function_t>", "k"),
          serializer.tuple("std::shared_ptr<function_t>", "t"),
          serializer.tuple("std::shared_ptr<function_t>", "h"))
        :map(serializer.template "%1 %2")
        :separated ", "
    ))
  end
end

local function generate_closure(out, self)
  local upvalues = self.upvalues
  local blocks = self.blocks
  local entry_uid = blocks.entry_uid
  local entry_params = blocks[entry_uid].params

  out:write(serializer.template [[
class %1 : public function_t {
public:
  %1(%2)%3 {}
private:
  std::function<void()> operator()(std::shared_ptr<function_t> k, std::shared_ptr<function_t> t, std::shared_ptr<function_t> h, array_t args) {
%4%
    return %1_%5(%6);
  }
%7%
};
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
            return serializer.tuple("value_t", var, "[" .. var.number .. "]")
          end
        elseif key == "V" then
          return serializer.tuple("array_t", var, ".sub(" .. self.A .. ")")
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
      :unshift("k", "t", "h")
      :separated ", ",
    serializer.sequence(upvalues)
      :map(function (item) return item[1] end)
      :map(serializer.template "  ref_t %1;\n")
  ))
end

local function generate_definitions(out, proto_name, blocks, postorder)
  for i = #postorder, 1, -1 do
    local uid = postorder[i]
    local block = blocks[uid]

    out:write(serializer.template "std::function<void()> %1_%2(%3) {\n" (
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
            return serializer.tuple("value_t", var)
          end
        end)
        :sort(function (a, b) return a[2] < b[2] end)
        :unshift(
          serializer.tuple("std::shared_ptr<function_t>", "k"),
          serializer.tuple("std::shared_ptr<function_t>", "t"),
          serializer.tuple("std::shared_ptr<function_t>", "h"))
        :map(serializer.template "%1 %2")
        :separated ", "
    ))

    for j = 1, #block do
      local code = block[j]
      local name = code[0]

      local tmpl = templates[name]
      if tmpl then
        local var = code[1]
        if var.declare then
          out:write "  "
          if var.reference then
            out:write "ref_t"
          elseif var.type == "array" then
            out:write "array_t"
          else
            out:write "value_t"
          end
          out:write(" ", tmpl(unpack(code)), ";\n")
        else
          out:write("  ", tmpl(unpack(code)), ";\n")
        end
      end
    end

    out:write "}\n"
  end
end

return function (self, out)
  local blocks = self.blocks
  local g = blocks.g
  local uv_postorder = g:uv_postorder(blocks.entry_uid)
  generate_declations(out, self[1], blocks, uv_postorder)
  generate_closure(out, self)
  generate_definitions(out, self[1], blocks, uv_postorder)
  return out
end
