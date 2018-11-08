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

local function generate(proto, flat_code, code, break_label)
  local name = code[0]

  if code.block then
    if name == "LOOP" then
      local n = proto.M
      local x = "M" .. n
      local y = "M" .. n + 1
      proto.M = n + 2
      flat_code[#flat_code + 1] = { [0] = "LABEL", x }
      for i = 1, #code do
        generate(proto, flat_code, code[i], y)
      end
      flat_code[#flat_code + 1] = { [0] = "GOTO", x }
      flat_code[#flat_code + 1] = { [0] = "LABEL", y }
    elseif name == "COND" then
      local cond = code[1]
      if #code == 2 then
        local n = proto.M
        local x = "M" .. n
        local y = "M" .. n + 1
        proto.M = n + 2
        flat_code[#flat_code + 1] = { [0] = "COND", cond[1], cond[2], x, y }
        flat_code[#flat_code + 1] = { [0] = "LABEL", x }
        generate(proto, flat_code, code[2], break_label)
        flat_code[#flat_code + 1] = { [0] = "LABEL", y }
      else
        local n = proto.M
        local x = "M" .. n
        local y = "M" .. n + 1
        local z = "M" .. n + 2
        proto.M = n + 3
        flat_code[#flat_code + 1] = { [0] = "COND", cond[1], cond[2], x, y }
        flat_code[#flat_code + 1] = { [0] = "LABEL", x }
        generate(proto, flat_code, code[2], break_label)
        flat_code[#flat_code + 1] = { [0] = "GOTO", z }
        flat_code[#flat_code + 1] = { [0] = "LABEL", y }
        generate(proto, flat_code, code[3], break_label)
        flat_code[#flat_code + 1] = { [0] = "LABEL", z }
      end
    else
      for i = 1, #code do
        generate(proto, flat_code, code[i], break_label)
      end
    end
  else
    if name == "BREAK" then
      flat_code[#flat_code + 1] = { [0] = "GOTO", break_label }
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
    proto.M = 0
    proto.flat_code = flat_code
    generate(proto, flat_code, proto.tree_code)
  end
  return self
end
