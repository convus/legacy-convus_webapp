// NOTE: full disclosure - I have no idea what the best practices are for structuring JS
// I'm just winging it.
// ... sry

import TimeParser from "./utils/time_parser";
import log from "./utils/log";
import LoadFancySelects from "./utils/load_fancy_selects.js";

$(document).on("turbolinks:load", function () {
  if (!window.timeParser) {
    window.timeParser = new TimeParser();
  }
  window.timeParser.localize();

  // And load fancy selects after everything, in case something added more fancy selects
  LoadFancySelects();
});
