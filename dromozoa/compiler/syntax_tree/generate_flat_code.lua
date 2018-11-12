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

local variable = require "dromozoa.compiler.variable"

local function generate(proto, flat_code, code, last_label)
  local name = code[0]

  if code.block then
    if name == "LOOP" then
      local n = proto.M
      local loop_label = variable.M(n)
      local join_label = variable.M(n + 1)
      proto.M = n + 2
      flat_code[#flat_code + 1] = { [0] = "LABEL", loop_label }
      for i = 1, #code do
        generate(proto, flat_code, code[i], join_label)
      end
      flat_code[#flat_code + 1] = { [0] = "GOTO", loop_label }
      flat_code[#flat_code + 1] = { [0] = "LABEL", join_label }
    elseif name == "COND" then
      local cond = code[1]
      if #code == 2 then
        local n = proto.M
        local then_label = variable.M(n)
        local join_label = variable.M(n + 1)
        proto.M = n + 2
        flat_code[#flat_code + 1] = { [0] = "COND", cond[1], cond[2], then_label, join_label }
        flat_code[#flat_code + 1] = { [0] = "LABEL", then_label }
        generate(proto, flat_code, code[2], last_label)
        flat_code[#flat_code + 1] = { [0] = "LABEL", join_label }
      else
        local n = proto.M
        local then_label = variable.M(n)
        local else_label = variable.M(n + 1)
        local join_label = variable.M(n + 2)
        proto.M = n + 3
        flat_code[#flat_code + 1] = { [0] = "COND", cond[1], cond[2], then_label, else_label }
        flat_code[#flat_code + 1] = { [0] = "LABEL", then_label }
        generate(proto, flat_code, code[2], last_label)
        flat_code[#flat_code + 1] = { [0] = "GOTO", join_label }
        flat_code[#flat_code + 1] = { [0] = "LABEL", else_label }
        generate(proto, flat_code, code[3], last_label)
        flat_code[#flat_code + 1] = { [0] = "LABEL", join_label }
      end
    else
      for i = 1, #code do
        generate(proto, flat_code, code[i], last_label)
      end
    end
  else
    if name == "BREAK" then
      flat_code[#flat_code + 1] = { [0] = "GOTO", last_label }
    else
      flat_code[#flat_code + 1] = code
    end
  end
end

return function (self)
  local protos = self.protos
  for i = 1, #protos do
    local proto = protos[i]
    local flat_code = { block = true }
    proto.flat_code = flat_code
    generate(proto, flat_code, proto.tree_code)
  end
  return self
end
