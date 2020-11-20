// NOTE: full disclosure - I have no idea what the best practices are for structuring JS
// I'm just winging it. sry

import TimeParser from "./utils/time_parser";
import log from "./utils/log";
import LoadFancySelects from "./utils/load_fancy_selects.js";
import PeriodSelector from "./utils/period_selector.js";

// And also include chartkick
import Chartkick from "chartkick";
window.Chartkick = Chartkick;
import Chart from "chart.js";
Chartkick.addAdapter(Chart);

import { HypothesisForm } from "../scripts/sections/hypothesis_form.js";

$(document).on("turbolinks:load", function() {
  if (!window.timeParser) {
    window.timeParser = new TimeParser();
  }
  window.timeParser.localize();
  // Period selector
  if ($("#timeSelectionBtnGroup").length) {
    const periodSelector = PeriodSelector();
    periodSelector.init();
  }

  if ($("#hypothesisForm").length) {
    window.hypothesisForm = new HypothesisForm();
    hypothesisForm.init();
  }

  // And load fancy selects after everything, in case something added more fancy selects
  LoadFancySelects();
});
