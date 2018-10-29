// Copyright (C) 2018 Tomoyuki Fujimori <moyu@dromozoa.com>
//
// This file is part of dromozoa-compiler.
//
// dromozoa-compiler is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// dromozoa-compiler is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// Under Section 7 of GPL version 3, you are granted additional
// permissions described in the GCC Runtime Library Exception, version
// 3.1, as published by the Free Software Foundation.
//
// You should have received a copy of the GNU General Public License
// and a copy of the GCC Runtime Library Exception along with
// dromozoa-compiler.  If not, see <http://www.gnu.org/licenses/>.

const metatable_key = Symbol("metatabale");

class Error {
  constructor(message) {
    this.message = message;
  }
}

const getmetafield = (object, event) => {
  const metatable = object[metatable_key];
  if (metatable !== undefined) {
    return metatable.get(event);
  }
};

const call0 = (f, ...args) => {
  if (typeof f === "function") {
    f(...args);
  } else {
    getmetafield(f, "__call")(f, ...args);
  }
};

const call1 = (f, ...args) => {
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

const call = (f, ...args) => {
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

const gettable = (table, index) => {
  const result = table.get(index);
  if (result === undefined) {
    const field = getmetafield(table, "__index");
    if (field !== undefined) {
      if (typeof field === "function") {
        return call1(field, table, index);
      } else {
        return gettable(field, index);
      }
    }
  }
  return result;
};

const settable = (table, index, value) => {
  const result = table.get(index);
  if (result === undefined) {
    const field = getmetafield(table, "__newindex");
    if (field !== undefined) {
      if (typeof field === "function") {
        return call0(field, table, index, value);
      } else {
        return settable(field, index, value);
      }
    }
  }
  if (value === undefined) {
    table.delete(index);
  } else {
    table.set(index, value);
  }
};

const len = value => {
  if (Map.prototype.isPrototypeOf(value)) {
    const field = getmetafield(value, "__len");
    if (field !== undefined) {
      return call1(field, value);
    }
    for (let i = 1; ; ++i) {
      if (value.get(i) === undefined) {
        return i - 1;
      }
    }
  }
};

const setlist = (table, index, ...args) => {
  for (let i = 0; i < args.length; ++i) {
    table.set(index + i, args[i]);
  }
};

const tonumber = value => {
  if (typeof value == "number") {
    return value;
  }
};

const tostring = value => {
  const t = typeof value;
  if (t === "undefined") {
    return "nil";
  } else if (t === "number") {
    return value.toString();
  } else if (t === "string") {
    return value;
  } else if (t === "boolean") {
    if (value) {
      return "true";
    } else {
      return "false";
    }
  } else if (t === "function") {
    return "function";
  } else if (Map.prototype.isPrototypeOf(value)) {
    const field = getmetafield(value, "__tostring");
    if (field !== undefined) {
      return call1(field, value);
    } else {
      return "table";
    }
  }
  return "userdata";
};

const open_env = () => {
  const ipairs_iterator = (table, index) => {
    ++index;
    const value = gettable(table, index);
    if (value !== undefined) {
      return [index, value];
    }
  };

  const env = new Map();

  env.set("_G", env);
  env.set("_VERSION", "Lua 5.3");
  env.set("tonumber", tonumber);
  env.set("tostring", tostring);

  env.set("assert", (...args) => {
    const value = args[0];
    if (value === undefined || value === false) {
      if (args.length > 1) {
        throw new Error(args[1]);
      } else {
        throw new Error("assertion failed!");
      }
    }
    return args;
  });

  env.set("error", message => {
    throw new Error(message);
  });

  env.set("getmetatable", object => {
    const metatable = object[metatable_key];
    if (metatable !== undefined) {
      if (metatable.has("__metatable")) {
        return metatable.get("__metatable");
      }
    }
    return metatable;
  });

  env.set("ipairs", table => {
    return [ipairs_iterator, table, 0];
  });

  env.set("pcall", (f, ...args) => {
    try {
      const result = call(f, ...args);
      return [true, ...result];
    } catch (e) {
      if (Error.prototype.isPrototypeOf(e)) {
        return [false, e.message];
      }
      throw e;
    }
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

  env.set("select", (index, ...args) => {
    if (index === "#") {
      return args.length;
    }
    if (index < 0) {
      index += args.length;
    } else {
      --index;
    }
    const result = [];
    for (let i = index; i < args.length; ++i) {
      result.push(args[i]);
    }
    return result;
  });

  env.set("setmetatable", (table, metatable) => {
    if (getmetafield(table, "__metatable") !== undefined) {
      throw new Error("cannot change a protected metatable");
    }
    table[metatable_key] = metatable;
    return table;
  });

  env.set("type", value => {
    const t = typeof value;
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
    } else if (Map.prototype.isPrototypeOf(value)) {
      return "table";
    }
    return "userdata";
  });

  return env;
};
