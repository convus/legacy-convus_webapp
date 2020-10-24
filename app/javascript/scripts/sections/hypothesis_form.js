import log from "../utils/log";

export class HypothesisForm {
  init() {
    $("#submitForApproval").on("click", (e) => {
      log.debug("dddddddd");
      e.preventDefault();
      $("#hypothesisForm .loadingSpinner").collapse("show");
      $(".submit-input").addClass("disabled");
      $("#hypothesis_add_to_github").val("1");
      $("#hypothesisForm").submit();
    });
  }
}
