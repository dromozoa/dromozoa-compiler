(function (root) {
  let $ = root.jQuery;
  let parseFloat = root.parseFloat;
  let pow = root.Math.pow;
  let duration = 2000;

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

  $(function () {
    let $svg = $("svg");
    let hw = parseFloat($svg.attr("width")) * 0.5;
    let hh = parseFloat($svg.attr("height")) * 0.5;
    let $view = $("g.view");

    let transform = new Transform();
    let mouse = {
      active: false,
      x: 0,
      y: 0,
    };

    $(".S").click(function () {
      let $text = $("g.u_texts > text[data-uid=" + $(this).data("uid") + "]");
      let v = {
        x: parseFloat($text.attr("x")),
        y: parseFloat($text.attr("y")),
      };
      transform.transform_vector(v);
      transform.translate_to(hw - v.x, hh - v.y);
      $view.attr("transform", transform.toString());
    });

    $(".viewport").on("mousedown", function ($ev) {
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
    $svg.on("wheel", function ($ev) {
      $ev.preventDefault();
      let ev = $ev.originalEvent;
      transform.scale(ev.offsetX, ev.offsetY, -ev.deltaY);
      $view.attr("transform", transform.toString());
    });
  });
}(window));
