return [[
const metatable_key = Symbol("metatabale");

const getmetafield = function (object, event) {
  const metatable = object[metatable_key];
  if (metatable !== undefined) {
    return metatable.get(event);
  }
};

const CALL0 = (f, ...args) => {
  if (typeof f === "function") {
    f(...args);
  } else {
    getmetafield(f, "__call")(f, ...args);
  }
};

const CALL1 = (f, ...args) => {
  let result;
  if (typeof f === "function") {
    result = f(...args);
  } else {
    result = getmetafield(f, "__call")(f, ...args);
  }
  if (Array.prototype.isPrototypeOf(result)) {
    return result[0];
  } else {
    return result;
  }
};

const CALL = (f, ...args) => {
  let result;
  if (typeof f === "function") {
    result = f(...args);
  } else {
    result = getmetafield(f, "__call")(f, ...args);
  }
  if (Array.prototype.isPrototypeOf(result)) {
    return result;
  } else {
    return [result];
  }
};

const GETTABLE = (table, index) => {
  const result = table.get(index);
  if (result === undefined) {
    const field = getmetafield(table, "__index");
    if (field !== undefined) {
      if (typeof field === "function") {
        return CALL1(field, table, index);
      } else {
        return GETTABLE(field, index);
      }
    }
  }
  return result;
};

const SETTABLE = (table, index, value) => {
  const result = table.get(index);
  if (result === undefined) {
    const field = getmetafield(table, "__newindex");
    if (field !== undefined) {
      if (typeof field === "function") {
        return CALL0(field, table, index, value);
      } else {
        return SETTABLE(field, index, value);
      }
    }
  }
  if (value === undefined) {
    table.delete(index);
  } else {
    table.set(index, value);
  }
};

const LEN = (v) => {
  if (Map.prototype.isPrototypeOf(v)) {
    const field = getmetafield(v, "__len");
    if (field !== undefined) {
      return CALL1(field, v);
    }
    for (let i = 1; ; ++i) {
      if (v.get(i) === undefined) {
        return i - 1;
      }
    }
  }
};

const SETLIST = (table, index, ...args) => {
  for (let i = 0; i < args.length; ++i) {
    table.set(index + i, args[i]);
  }
};

const tostring = (v) => {
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
  } else if (t === "function") {
    return "function";
  } else if (Map.prototype.isPrototypeOf(v)) {
    const field = getmetafield(v, "__tostring");
    if (field !== undefined) {
      return CALL1(field, v);
    } else {
      return "table";
    }
  }
  return "userdata";
};

const open_env = () => {
  class Error {
    constructor(message) {
      this.message = message;
    }
  }

  const env = new Map();

  env.set("tostring", tostring);

  env.set("getmetatable", (table) => {
    const metatable = table[metatable_key];
    if (metatable !== undefined) {
      if (metatable.has("__metatable")) {
        return metatable.get("__metatable");
      }
    }
    return metatable;
  });

  env.set("setmetatable", function (table, metatable) {
    if (getmetafield(table, "__metatable") !== undefined) {
      throw new Error("cannot change a protected metatable");
    }
    table[metatable_key] = metatable;
    return table;
  });

  env.set("type", (v) => {
    const t = typeof v;
    if (t === "undefined") {
      return "nil";
    } else if (t === "number") {
      return "number";
    } else if (t === "string") {
      return "string";
    } else if (t === "boolean") {
      return "boolean";
    } else if (t === "function") {
      return "function";
    } else if (Map.prototype.isPrototypeOf(v)) {
      return "table";
    }
    return "userdata";
  });

  env.set("print", (...args) => {
    for (let i = 0; i < args.length; ++i) {
      if (i > 0) {
        process.stdout.write("\t");
      }
      process.stdout.write(tostring(args[i]));
    }
    process.stdout.write("\n");
  });

  env.set("assert", (...args) => {
    const v = args[0];
    if (v === undefined || v === false) {
      if (args.length > 1) {
        throw new Error(args[1]);
      } else {
        throw new Error("assertion failed");
      }
    }
    return args;
  });

  return env;
};
]]
