import log from "../utils/log";
import KeyboardOrClick from "../utils/keyboard_or_click.js";

export class HypothesisForm {
  constructor() {
    const kinds = $("#citationsBlock").attr("data-ckinds") || "";
    const research = $("#citationsBlock").attr("data-cresearchkinds") || "";
    this.citationKinds = kinds.split(",");
    this.researchKinds = research.split(",");
  }

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
      // Need to re-load fancy selects here, if we add fields with fancy selects
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
      // TODO: There is an issue in Firefox where this will collapse multiple if they were added close together
      // slideUp() didn't fix the problem, and I got tired of trying to fix it, so ignoring
      // log.debug($eventTarget);

      $eventTarget.find(".hasRequired").removeAttr("required");
      $eventTarget.first().collapse("hide");
    });

    // Update all the citation fields
    Array.from(
      document.getElementsByClassName("citationFields")
    ).forEach((el) => this.updateCitationFields($(el)));
    // On citation kind change, update citation
    $("#citationsBlock").on("change", ".kindSelect", (event) => {
      this.updateCitationFields($(event.target).parents(".citationFields"));
    });
  }

  updateCitationFields($fields) {
    const kind = $fields.find(".kindSelect").val();
    const researchKind = this.researchKinds.includes(kind);
    const kindDisplay = kind; // Will be more sophisticated
    log.debug(kind, researchKind);
    // Toggle the kind
    $fields.find(".kindResearchField").collapse(researchKind ? "show" : "hide");
    // Update the places it should show kind
    $fields
      .find(".kindDisplayText")
      .text(researchKind ? "Research" : kindDisplay);
  }
}
