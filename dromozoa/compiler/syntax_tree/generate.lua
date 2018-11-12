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

local generate_basic_blocks = require "dromozoa.compiler.syntax_tree.generate_basic_blocks"
local generate_flat_code = require "dromozoa.compiler.syntax_tree.generate_flat_code"
local generate_tree_code = require "dromozoa.compiler.syntax_tree.generate_tree_code"

return function (self)
  generate_tree_code(self)
  -- generate_flat_code(self)
  generate_basic_blocks(self)
  return self
end
