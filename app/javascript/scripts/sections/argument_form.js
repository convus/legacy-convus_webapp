import log from "../utils/log";

// TODO: make less dependent on jquery
export class ArgumentForm {
  init() {
    // maybe should be based on the power of the device that is editing?
    const THROTTLE_LIMIT = 500;

    // This is not how this should be done :(
    // but I'm too lazy to figure out context for throttle, so just setting things on the window
    window.updateBlockquote = this.updateBlockquote;
    window.similarity = this.similarity;
    window.editDistance = this.editDistance;
    window.looksLikeMatch = this.looksLikeMatch;
    window.parseArgumentQuotes = this.parseArgumentQuotes;
    window.parseExistingQuotes = this.parseExistingQuotes;

    $("#argument_text").on(
      "keydown keyup update blur",
      this.throttle(this.updateArgumentQuotes, THROTTLE_LIMIT)
    );
  }

  updateArgumentQuotes() {
    const newBlockQuotes = window.parseArgumentQuotes(
      $("#argument_text").val()
    );

    // In additional to throttling - if the quotes haven't changed, don't process
    if (newBlockQuotes == window.newBlockQuotes) {
      log.debug("same as previous quotes");
      return;
    }

    window.blockQuotes = newBlockQuotes;

    window.existingQuotes = window.parseExistingQuotes();

    log.debug(blockQuotes, existingQuotes);
    // $("#quoteFields .quote-field").addClass("unprocessed");

    // blockQuotes.forEach((text, index) => window.updateBlockquote(text, index));
  }

  parseArgumentQuotes(text) {
    const regexp = /^|\n\s?>[^\n]*/g;

    return text.match(regexp) || [];
  }

  parseExistingQuotes() {
    const existingQuotes = {};

    $("#quoteFields .quote-field").each(function(index) {
      const $this = $(this);
      log.debug($this);
      existingQuotes[String(index)] = {
        matched: false,
        text: $this.find(".quote-text").text(),
        removed: $this.hasClass("removed"),
      };
    });
    return existingQuotes;
  }

  updateBlockquote(text, index) {
    const regexp = /\^|\n\s?>/i;
    const quoteText = text.replace(regexp, "");

    let quoteMatchIndex = null;

    // // If there is only one block quote, assume this is it.
    // if (window.blockQuotes.length == 1 && index == 0 && ) {
    //   quoteMatchIndex = index;
    // }
    if ($("#quoteFields .quote-field.unprocessed").length) {
      log.debug("ffffff");
      // First, check if the index matched quote field matches and set it if so.
      if ($("#quoteFields .quote-field")[index].length) {
        // Might want to make this match loser if this is the last quote in the argument
        log.debug(`quote field index!! ${index}`);
        if (window.looksLikeMatch($("#quoteFields .quote-field")[index])) {
          quoteMatchIndex = index;
        }
      }
    }

    // test quoteMatches - one of the existing quote elements matches the text closely enough
    let $quoteField = null;
    log.debug(
      `blockquote length: ${window.blockQuotes.length} index: ${index} quoteMatchIndex: ${quoteMatchIndex}`
    );
    if (quoteMatchIndex !== null) {
      log.debug("matched something!");
      $quoteField = $($("#quoteFields .quote-field")[index]);
      $quoteField.removeClass("unprocessed");
      $quoteField.find(".quote-text").text(quoteText);
    } else {
      log.debug("new field");
      const field =
        index == 0 ? $("#quoteFields") : $("#quoteFields .quote-field")[index];
      // log.debug(field);

      field.prepend(
        `<div class="quote-field"><p class="quote-text">${quoteText}</p></div>`
      );
    }
  }

  // h/t to https://towardsdev.com/debouncing-and-throttling-in-javascript-8862efe2b563
  throttle(func, limit) {
    let lastFunc;
    let lastRan;
    return function() {
      const context = this;
      const args = arguments;
      if (!lastRan) {
        func.apply(context, args);
        lastRan = Date.now();
      } else {
        clearTimeout(lastFunc);
        lastFunc = setTimeout(function() {
          if (Date.now() - lastRan >= limit) {
            func.apply(context, args);
            lastRan = Date.now();
          }
        }, limit - (Date.now() - lastRan));
      }
    };
  }

  looksLikeMatch(quote, quoteEl) {
    $quoteEl = $(quoteEl);
    // Make sure it isn't processed
    if (!$quoteEl.hasClass("unprocessed")) {
      log.debug("has class!!!");
      return false;
    }
    return true;
  }

  // levenstein matching (TODO: improve)
  // h/t https://stackoverflow.com/questions/10473745/compare-strings-javascript-return-of-likely
  similarity(s1, s2) {
    let longer = s1;
    let shorter = s2;
    if (s1.length < s2.length) {
      longer = s2;
      shorter = s1;
    }
    const longerLength = longer.length;
    if (longerLength == 0) {
      return 1.0;
    }
    return (
      (longerLength - editDistance(longer, shorter)) / parseFloat(longerLength)
    );
  }

  editDistance(s1, s2) {
    s1 = s1.toLowerCase();
    s2 = s2.toLowerCase();

    const costs = new Array();
    for (let i = 0; i <= s1.length; i++) {
      let lastValue = i;
      for (let j = 0; j <= s2.length; j++) {
        if (i == 0) costs[j] = j;
        else {
          if (j > 0) {
            let newValue = costs[j - 1];
            if (s1.charAt(i - 1) != s2.charAt(j - 1)) {
              newValue = Math.min(Math.min(newValue, lastValue), costs[j]) + 1;
            }
            costs[j - 1] = lastValue;
            lastValue = newValue;
          }
        }
      }
      if (i > 0) costs[s2.length] = lastValue;
    }
    return costs[s2.length];
  }
}
