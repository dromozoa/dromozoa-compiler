return [[
const CALL0 = function (f, ...args) {
  f(...args);
};

const CALL1 = function (f, ...args) {
  const result = f(...args);
  if (typeof result === "object" && Array.prototype.isPrototypeOf(result)) {
    return result[0];
  } else {
    return result;
  }
};

const CALL = function (f, ...args) {
  const result = f(...args);
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

const LEN = function (v) {
  if (typeof v === "object" && Map.prototype.isPrototypeOf(v)) {
    for (let i = 1; ; ++i) {
      if (v.get(i) === undefined) {
        return i - 1;
      }
    }
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

const type = function (v) {
  const t = typeof v;
  if (t === "undefined") {
    return "nil";
  } else if (t === "number") {
    return "number"
  } else if (t === "string") {
    return "string"
  } else if (t === "boolean") {
    return "boolean"
  } else if (t === "object") {
    if (Map.prototype.isPrototypeOf(v)) {
      return "table";
    }
  } else if (t === "function") {
    return "function";
  }
  return "userdata";
}

const open_env = function () {
  const env = new Map();

  env.set("tostring", tostring);
  env.set("type", type);

  env.set("print", function (...args) {
    for (let i = 0; i < args.length; ++i) {
      if (i > 0) {
        process.stdout.write("\t");
      }
      process.stdout.write(tostring(args[i]));
    }
    process.stdout.write("\n");
  });

  env.set("assert", function (...args) {
    const v = args[0];
    if (v === undefined || v === false) {
      if (args.length > 1) {
        throw args[1];
      } else {
        throw "assertion failed"
      }
    }
    return args;
  });

  return env;
};
]]
