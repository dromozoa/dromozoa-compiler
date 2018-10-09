(function (root) {
  let $ = root.jQuery;
  let parseFloat = root.parseFloat;
  $(function () {

    let $svg = $("svg");
    let w = $svg.attr("width");
    let h = $svg.attr("height");
    let hw = w * 0.5;
    let hh = h * 0.5;
    let $translate = $("g.translate");
    let tx = 0;
    let ty = 0;
    let mouse;

    $(".S").click(function () {
      let $text = $("g.u_texts > text[data-uid=" + $(this).attr("id").substr(1) + "]");
      tx = hw - $text.attr("x");
      ty = hh - $text.attr("y");
      $translate.attr("transform", "translate(" + tx + " " + ty + ")");
    });

    $(".background").on("mousedown", function (ev) {
      mouse = {
        x: ev.originalEvent.offsetX,
        y: ev.originalEvent.offsetY,
      };
    }).on("mousemove", function (ev) {
      if (mouse) {
        let x = ev.originalEvent.offsetX;
        let y = ev.originalEvent.offsetY;
        tx += x - mouse.x;
        ty += y - mouse.y;
        $translate.attr("transform", "translate(" + tx + " " + ty + ")");
        mouse.x = x;
        mouse.y = y;
      }
      // console.log("mousemove", ev);
    }).on("mouseup", function () {
      mouse = undefined;
    });


  });
}(window));
