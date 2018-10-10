(function (root) {
  let parseFloat = root.parseFloat;
  let requestAnimationFrame = root.requestAnimationFrame;
  let pow = root.Math.pow;
  let $ = root.jQuery;
  let duration = 400;

  let Transform = class {
    constructor() {
      this.k = 1.002;
      this.s = 1;
      this.x = 0;
      this.y = 0;
    }

    toString() {
      return "translate(" + this.x + " " + this.y + ") scale(" + this.s + ")";
    }

    set(that) {
      this.k = that.k;
      this.s = that.s;
      this.x = that.x;
      this.y = that.y;
    }

    interpolate(a, b, t) {
      let alpha = t;
      let beta = 1 - t;
      this.k = a.k * beta + b.k * alpha;
      this.s = a.s * beta + b.s * alpha;
      this.x = a.x * beta + b.x * alpha;
      this.y = a.y * beta + b.y * alpha;
    }

    translate(x, y) {
      this.x += x;
      this.y += y;
    }

    translate_to(x, y) {
      this.x = x;
      this.y = y;
    }

    scale(x, y, d) {
      let t = pow(this.k, d)
      this.s *= t;
      this.x = (this.x - x) * t + x;
      this.y = (this.y - y) * t + y;
    }

    transform_vector(v) {
      let s = this.s;
      v.x *= s;
      v.y *= s;
    }
  };

  let click = function (uid) {
    $(".active").removeClass("active");
    $(".S" + uid).addClass("active");
    let $path = $("g.u_paths > path[data-uid=" + uid + "]");
    $path.addClass("active");
    console.log(uid, $path.data("value"));
  };

  $(function () {
    let $svg = $("svg");
    let hw = parseFloat($svg.attr("width")) * 0.5;
    let hh = parseFloat($svg.attr("height")) * 0.5;
    let $view = $("g.view");

    let transform = new Transform();

    let animation = {
      t: false,
      a: new Transform(),
      b: new Transform(),
    };

    let animation_step = function (t) {
      if (!animation.t) {
        animation.t = t;
      }
      let d = t - animation.t;
      if (d < duration) {
        transform.interpolate(animation.a, animation.b, d / duration);
        $view.attr("transform", transform.toString());
        requestAnimationFrame(animation_step);
      } else {
        animation.t = false;
        transform.set(animation.b);
        $view.attr("transform", transform.toString());
      }
    };

    let mouse = {
      active: false,
      x: 0,
      y: 0,
    };

    $(".S").on("click", function () {
      let uid = $(this).data("uid");
      let $text = $("g.u_texts > text[data-uid=" + uid + "]");
      let v = {
        x: parseFloat($text.attr("x")),
        y: parseFloat($text.attr("y")),
      };
      let a = animation.a;
      let b = animation.b;
      a.set(transform);
      b.set(transform);
      b.transform_vector(v);
      b.translate_to(hw - v.x, hh - v.y);
      animation.t = false;
      requestAnimationFrame(animation_step);
      click(uid);
    });

    $("g.u_texts > text").on("click", function () {
      click($(this).data("uid"));
    });

    $svg.on("wheel", function ($ev) {
      $ev.preventDefault();
      let ev = $ev.originalEvent;
      transform.scale(ev.offsetX, ev.offsetY, -ev.deltaY);
      $view.attr("transform", transform.toString());
    });

    $("rect.viewport").on("mousedown", function ($ev) {
      let ev = $ev.originalEvent;
      mouse.active = true;
      mouse.x = ev.offsetX;
      mouse.y = ev.offsetY;
    }).on("mousemove", function ($ev) {
      if (mouse.active) {
        let ev = $ev.originalEvent;
        let x = ev.offsetX;
        let y = ev.offsetY;
        transform.translate(x - mouse.x, y - mouse.y);
        mouse.x = x;
        mouse.y = y;
        $view.attr("transform", transform.toString());
      }
    }).on("mouseup", function ($ev) {
      let ev = $ev.originalEvent;
      mouse.active = false;
      mouse.x = ev.offsetX;
      mouse.y = ev.offsetX;
    });
  });
}(window));
