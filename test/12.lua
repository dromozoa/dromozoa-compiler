local function f()
end

local function f()
  io.write "foo"
  io.write "bar"
  io.write "baz"
end

local function f()
  io.write "foo"
  io.write "bar"
  io.write "baz"
  return
end

local function f()
  io.write "foo"
  io.write "bar"
  io.write "baz"
  return;
end

local function f()
  io.write "foo"
  io.write "bar"
  io.write "baz"
  return 1, 2, 3
end

local function f()
  io.write "foo"
  io.write "bar"
  io.write "baz"
  return 1, 2, 3;
end

local x = 42
return x
