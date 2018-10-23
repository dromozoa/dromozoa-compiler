return [[
const CALL0 = function (f, ...vararg) {
  f(...vararg);
};

const CALL1 = function (f, ...vararg) {
  const result = f(...vararg);
  if (typeof result === "object" && Array.prototype.isPrototypeOf(result)) {
    return result[0];
  } else {
    return result;
  }
};

const CALL = function (f, ...vararg) {
  const result = f(...vararg);
  if (typeof result === "object" && Array.prototype.isPrototypeOf(result)) {
    return result;
  } else {
    return [result];
  }
};

const GETTABLE = function (table, index) {
  return table.get(index);
};

const SETTABLE = function (table, index, value) {
  if (value === undefined) {
    table.delete(index);
  } else {
    table.set(index, value);
  }
};

const tostring = function (v) {
  const t = typeof v;
  if (t === "undefined") {
    return "nil";
  } else if (t === "number") {
    return v.toString();
  } else if (t === "string") {
    return v;
  } else if (t === "boolean") {
    if (v) {
      return "true";
    } else {
      return "false";
    }
  } else if (t === "object") {
    if (Map.prototype.isPrototypeOf(v)) {
      return "table";
    }
  } else if (t === "function") {
    return "function";
  }
  return "userdata";
};

const open_env = function () {
  const env = new Map();

  env.set("tostring", tostring);

  env.set("print", function (...vararg) {
    for (let i = 0; i < vararg.length; ++i) {
      if (i > 0) {
        process.stdout.write("\t");
      }
      process.stdout.write(tostring(vararg[i]));
    }
    process.stdout.write("\n");
  });

  env.set("assert", function (...vararg) {
    let v = vararg[0];
    if (v === undefined || v === false) {
      if (vararg.length > 1) {
        throw vararg[1];
      } else {
        throw "assertion failed"
      }
    }
    return vararg;
  });

  return env;
};
]]
