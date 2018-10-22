(function () {

  let tostring = function (v) {
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

  let env = new Map();

  env.set("print", function (...vararg) {
    const n = vararg.length - 1;
    for (let i = 0; i < n; ++i) {
      process.stdout.write(env_tostring(vararg[i]));
      process.stdout.write("\t");
    }
    process.stdout.write(env_tostring(vararg[n]));
    process.stdout.write("\n");
    return [];
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
}());
