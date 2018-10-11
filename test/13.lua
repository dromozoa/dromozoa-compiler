local a = 1
local a, b = 1, 2
local a, b, c = 1, 2, 3

local f = function () end
local f = function (a) end
local f = function (a, b) end
local f = function (...) end
local f = function (a, ...) end
local f = function (a, b, ...) end
