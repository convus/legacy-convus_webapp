import log from "../utils/log";
import KeyboardOrClick from "../utils/keyboard_or_click.js";

export class HypothesisForm {
  init() {
    $("#submitForApproval").on("click", (e) => {
      e.preventDefault();
      $("#hypothesisForm .loadingSpinner").collapse("show");
      $(".submit-input").addClass("disabled");
      $("#hypothesis_add_to_github").val("1");
      $("#hypothesisForm").submit();
    });

    $("form").on("click keyboard", ".add-fields", function(event) {
      event.preventDefault();
      if (!KeyboardOrClick(event)) {
        return false;
      }
      log.debug("add fields");
      const $target = $(".add-fields");
      const time = new Date().getTime();
      const regexp = new RegExp($target.data("id"), "g");
      // Potentially could use classnames to determine placement of new field
      $("#citationsBlock").append($target.data("fields").replace(regexp, time));
      // Need to re-load fancy selects here, if we ever add forms with fancy selects
    });
  }
}
