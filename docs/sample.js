(function (root) {
  let $ = root.jQuery;
  $(function () {
    $(".S").click(function () {
      console.log($(this));
    });
  });
}(window));
