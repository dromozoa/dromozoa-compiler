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

local function generate_declations(out, proto_name, blocks, postorder)
  for i = #postorder, 1, -1 do
    local uid = postorder[i]
    out:write(serializer.template "std::function<void()> %1_%2(%3);\n" (
      proto_name,
      uid,
      serializer.entries(blocks[uid].params)
        :map(function (encoded_var, param)
          local var
          if param.phi then
            var = param[0]
          else
            var = param
          end
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
  local proto_name = self[1]
  local upvalues = self.upvalues
  local blocks = self.blocks

  out:write(serializer.template [[
class %1 : public function_t {
public:
  %1(%2)%3 {}
private:
  std::function<void()> operator()(std::shared_ptr<function_t> k, std::shared_ptr<function_t> t, std::shared_ptr<function_t> h, array_t A) {
%4%
  }
%5%
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
    serializer.entries(blocks[blocks.entry_uid].params)
      :map(function (encoded_var, param)
        local var
        if param.phi then
          var = param[0]
        else
          var = param
        end
        if var.reference then
          return serializer.tuple("ref_t", var)
        elseif var.type == "array" then
          return serializer.tuple("array_t", var)
        else
          return serializer.tuple("value_t", var)
        end
      end)
      :sort(function (a, b) return a[2] < b[2] end)
      :map(serializer.template "    %1 %2;\n"),
    serializer.sequence(upvalues)
      :map(function (item) return item[1] end)
      :map(serializer.template "  ref_t %1;\n")
  ))
end

return function (self, out)
  local blocks = self.blocks
  local g = blocks.g
  local uv_postorder = g:uv_postorder(blocks.entry_uid)
  generate_declations(out, self[1], blocks, uv_postorder)
  generate_closure(out, self)
  return out
end
