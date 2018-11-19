(function () {
  "use strict";

  const pow = Math.pow;
  const $ = jQuery;
  const duration = 400;

  class Transform {
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
      const alpha = t;
      const beta = 1 - t;
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
      const t = pow(this.k, d);
      this.s *= t;
      this.x = (this.x - x) * t + x;
      this.y = (this.y - y) * t + y;
    }

    transform_vector(v) {
      const s = this.s;
      v.x *= s;
      v.y *= s;
    }
  }

  const click = function (node_id) {
    $(".active").removeClass("active");
    $(".node" + node_id).addClass("active");
    const $path = $("g.u_paths > path[data-node-id=" + node_id + "]");
    if ($path.get(0)) {
      $path.addClass("active");
      const data = [];
      $.each($path.get(0).attributes, function (_, attr) {
        const name = attr.name;
        if (name.startsWith("data-")) {
          data.push([ name.substr(5), attr.value ]);
        }
      });
      console.log(data);
    }
  };

  $(function () {
    const $svg = $("svg");
    const hw = parseFloat($svg.attr("width")) * 0.5;
    const hh = parseFloat($svg.attr("height")) * 0.5;
    const $view = $("g.view");
    const transform = new Transform();
    const animation = {
      t: false,
      a: new Transform(),
      b: new Transform(),
    };
    const animation_step = function (t) {
      if (!animation.t) {
        animation.t = t;
      }
      const d = t - animation.t;
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

    const mouse = {
      active: false,
      x: 0,
      y: 0,
    };

    $(".node").on("click", function () {
      const node_id = $(this).attr("data-node-id");
      if (node_id) {
        const $text = $("g.u_texts > text[data-node-id=" + node_id + "]");
        if ($text.get(0)) {
          const v = {
            x: parseFloat($text.attr("x")),
            y: parseFloat($text.attr("y")),
          };
          const a = animation.a;
          const b = animation.b;
          a.set(transform);
          b.set(transform);
          b.transform_vector(v);
          b.translate_to(hw - v.x, hh - v.y);
          animation.t = false;
          requestAnimationFrame(animation_step);
        }
        click(node_id);
      }
    });

    $("g.u_texts > text").on("click", function () {
      click($(this).attr("data-node-id"));
    });

    $svg.on("wheel", function ($ev) {
      $ev.preventDefault();
      const ev = $ev.originalEvent;
      transform.scale(ev.offsetX, ev.offsetY, -ev.deltaY);
      $view.attr("transform", transform.toString());
    });

    $("rect.viewport").on("mousedown", function ($ev) {
      const ev = $ev.originalEvent;
      mouse.active = true;
      mouse.x = ev.offsetX;
      mouse.y = ev.offsetY;
    }).on("mousemove", function ($ev) {
      if (mouse.active) {
        const ev = $ev.originalEvent;
        const x = ev.offsetX;
        const y = ev.offsetY;
        transform.translate(x - mouse.x, y - mouse.y);
        mouse.x = x;
        mouse.y = y;
        $view.attr("transform", transform.toString());
      }
    }).on("mouseup", function($ev) {
      const ev = $ev.originalEvent;
      mouse.active = false;
      mouse.x = ev.offsetX;
      mouse.y = ev.offsetX;
    });
  });
})(window);
