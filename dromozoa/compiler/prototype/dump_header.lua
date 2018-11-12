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

local function dump_use(out, item, key, indent)
  local use = item[key]
  if use[1] then
    out:write(indent, ("    %s %s\n"):format(key, table.concat(use, " ")))
  end
end

local function dump_items(out, self, key, indent, f)
  local items = self[key]
  if items[1] then
    out:write(indent, ("%s\n"):format(key))
    for i = 1, #items do
      f(items[i])
    end
  end
end

return function (self, out, indent)
  local parent = self.parent[1]
  if parent then
    out:write(indent, ("parent %s\n"):format(parent:encode()))
  end

  if self.self then
    out:write(indent, "self\n")
  end

  if self.vararg then
    out:write(indent, "vararg\n")
  end

  local keys = { "M", "A", "B", "C", "V", "T" }
  for i = 1, #keys do
    local key = keys[i]
    out:write(indent, ("%s %d\n"):format(key, self[key]))
  end

  dump_items(out, self, "labels", indent, function (item)
    out:write(indent, ("  %s %q\n"):format(item[1]:encode(), item.source))
    dump_use(out, item, "def", indent)
    dump_use(out, item, "use", indent)
  end)

  dump_items(out, self, "constants", indent, function (item)
    out:write(indent, ("  %s %q %s\n"):format(item[1]:encode(), item.source, item.type))
    dump_use(out, item, "use", indent)
  end)

  dump_items(out, self, "upvalues", indent, function (item)
    out:write(indent, ("  %s %s (%s %q)\n"):format(item[1]:encode(), item[2]:encode(), item.name[1], item.name.source))
  end)

  dump_items(out, self, "names", indent, function (item)
    out:write(indent, ("  %s %q\n"):format(item[1]:encode(), item.source))
    dump_use(out, item, "def", indent)
    dump_use(out, item, "use", indent)
    dump_use(out, item, "updef", indent)
    dump_use(out, item, "upuse", indent)
  end)

  return out
end
