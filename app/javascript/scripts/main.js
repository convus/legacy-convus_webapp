// NOTE: full disclosure - I have no idea what the best practices are for structuring JS
// I'm just winging it. sry

import TimeParser from "./utils/time_parser";
import log from "./utils/log";
import LoadFancySelects from "./utils/load_fancy_selects.js";
import { HypothesisForm } from "../scripts/sections/hypothesis_form.js";

$(document).on("turbolinks:load", function() {
  if (!window.timeParser) {
    window.timeParser = new TimeParser();
  }
  window.timeParser.localize();

  if ($("#hypothesisForm").length) {
    window.hypothesisForm = new HypothesisForm();
    hypothesisForm.init();
  }

  // And load fancy selects after everything, in case something added more fancy selects
  LoadFancySelects();
});
