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

    $(".add-fields").on("click keyboard", function(event) {
      event.preventDefault();
      if (!KeyboardOrClick(event)) {
        return false;
      }
      log.debug("add fields");
      const $target = $(".add-fields").clone();
      const time = new Date().getTime();
      const regexp = new RegExp($target.data("id"), "g");
      // Potentially could use classnames to determine placement of new field
      let newFields = $target.data("fields");
      $("#citationsBlock").append(newFields.replace(regexp, time));
      $("#citationsBlock .initially-hidden").collapse("show");
      $("#citationsBlock .initially-hidden").removeClass("initially-hidden");
      // Need to re-load fancy selects here, if we ever add forms with fancy selects
    });

    $("#citationsBlock").on("click keyboard", ".remove-fields", function(
      event
    ) {
      if (!KeyboardOrClick(event)) {
        return false;
      }
      // For this to work, the top level element in the nested fields needs to have the class "nested-field"
      const $eventTarget = $(event.target)
        .parents(".nested-field")
        .first();
      log.debug($eventTarget);
      $eventTarget.find(".hasRequired").removeAttr("required");
      // $eventTarget.first().collapse("hide");
      // Trying slideUp because bootstrap collapse was breaking things - making multiple blocks collapse
      $eventTarget.first().slideUp();

      // const targetId = $(event.target)
      //   .parents(".nested-field")
      //   .attr("id");

      // log.debug(targetId);
      // $(`#${targetId} .hasRequired`).removeAttr("required");
      // $(`#${targetId}`).collapse("hide");
    });
  }
}
