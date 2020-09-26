// NOTE: full disclosure - I have no idea what the best practices are for structuring JS
// I'm just winging it.
// ... sry

import TimeParser from "./utils/time_parser";
import log from "./utils/log";

$(document).on("turbolinks:load", function () {
  log.debug("party");

  if (!window.timeParser) {
    window.timeParser = new TimeParser();
  }
  window.timeParser.localize();
});
