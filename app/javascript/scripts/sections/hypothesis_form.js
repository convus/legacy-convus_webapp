import log from "../utils/log";
import KeyboardOrClick from "../utils/keyboard_or_click.js";

export class HypothesisForm {
  constructor() {
    const $el = $("#citationsBlock");
    this.challengeKinds = ($el.attr("data-challengekinds") || "").split(",");
    this.sameKinds = ($el.attr("data-challengesamekinds") || "").split(",");
    this.citationKinds = ($el.attr("data-citekinds") || "").split(",");
    this.researchKinds = ($el.attr("data-citeresearchkinds") || "").split(",");
  }

  init() {
    $("#submitForApproval").on("click", (e) => {
      e.preventDefault();
      $("#hypothesisForm .loadingSpinner").collapse("show");
      $(".submit-input").addClass("disabled");
      $(".addToGithubField").val("1");
      $("#hypothesisForm").submit();
    });

    this.enableAddAndRemoveCitations();

    // Update all the citation fields
    Array.from(
      document.getElementsByClassName("hypothesisCitationFields")
    ).forEach((el) => {
      this.updateChallengeKind($(el));
      this.updateCitationKind($(el));
    });

    $("#citationsBlock").on("change", ".challengeKindSelect", (event) => {
      this.updateChallengeKind(
        $(event.target).parents(".hypothesisCitationFields")
      );
    });

    $("#citationsBlock").on("change", ".citationKindSelect", (event) => {
      this.updateCitationKind(
        $(event.target).parents(".hypothesisCitationFields")
      );
    });
  }

  enableAddAndRemoveCitations() {
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
  }

  updateChallengeKind($fields) {
    // Generally there isn't a challenge kind select
    if (!$fields.find(".challengeKindSelect").length) {
      return null;
    }
    const challengeKind = $fields.find(".challengeKindSelect").val();

    if (this.sameKinds.includes(challengeKind)) {
      // It's currently challenge_same_citation_kind
      $fields.find(".challengeNewCitationField").collapse("hide");
      $fields
        .find(".challengeNewCitationField .hasRequired")
        .removeAttr("required");
    } else {
      $fields.find(".challengeNewCitationField").collapse("show");
      $fields
        .find(".challengeNewCitationField .hasRequired")
        .addAttr("required");
    }
    // // Toggle the kind
    // $fields
    //   .find(".challengeNewCitationField")
    //   .collapse(isSameCitationKind ? "hide" : "show");
    // if (isSameCitationKind) {
    //   $fields
    //   .find(".challengeNewCitationField .hasRequired")
    // }
  }

  updateCitationKind($fields) {
    const citationKind = $fields.find(".citationKindSelect").val();
    const isResearchKind = this.researchKinds.includes(citationKind);
    // Toggle the kind
    $fields
      .find(".kindResearchField")
      .collapse(isResearchKind ? "show" : "hide");
  }
}
