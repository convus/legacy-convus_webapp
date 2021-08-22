import log from '../utils/log'
import _ from 'lodash' // TODO: only import the parts needed

// TODO: make less dependent on jquery
export default class ArgumentForm {
  // Enable passing in, primarily for testing
  constructor ({ blockQuotes, existingQuotes, throttleLimit }) {
    this.blockQuotes = blockQuotes
    this.existingQuotes = existingQuotes
    // maybe should be based on the power of the device that is editing?
    this.throttleLimit = throttleLimit || 500
  }

  // init is called when loaded on the page - and not in testing
  init () {
    // assign initial state based on the dom
    this.blockQuotes = (this.blockQuotes !== undefined)
      ? this.blockQuotes
      : this.parseArgumentQuotes(
        $('#argument_text').val()
      )
    this.existingQuotes = (this.existingQuotes !== undefined)
      ? this.existingQuotes
      : this.parseExistingQuotes()

    log.debug(this.existingQuotes)

    $('#argument_text').on(
      'keydown keyup update blur',
      this.throttle(this.updateArgumentQuotes, this.throttleLimit)
    )
  }

  parseArgumentQuotes (text) {
    // Regex out the blockquote sections
    const quoteRegexp = /(^|\n)\s*>[^\n]*/g
    const match = text.match(quoteRegexp) || []

    // regex out the "> " from the quotes
    // - ignore any empty quotes
    // - Trim the string
    // - remove duplicates
    const replaceRegexp = /(^|\n)\s*>/
    return _.uniq(match.map(str => str.replace(replaceRegexp, '').trim())
      .filter(str => str.length > 0))
  }

  parseExistingQuotes () {
    const existingQuotes = {}

    $('#quoteFields .quote-field').each(function (index) {
      const $this = $(this)
      existingQuotes[String(index)] = {
        matched: false,
        text: $this.find('.quote-text').text().trim(),
        id: $this.find('.ref-number-field').val(),
        removed: $this.hasClass('removed')
      }
    })
    return existingQuotes
  }

  updateArgumentQuotes () {
    const newBlockQuotes = this.parseArgumentQuotes(
      $('#argument_text').val()
    )
    // In additional to throttling - if the quotes haven't changed, don't process
    if (_.isEqual(this.blockQuotes, newBlockQuotes)) {
      return
    }

    this.blockQuotes = newBlockQuotes
    this.existingQuotes = this.parseExistingQuotes()

    this.blockQuotes.forEach((text, index) => window.renderQuote(false, text, index))
    // THEN - for any unmatched existing quotes, update them to be removed
  }

  // NOTE: for removed quotes, index doesn't matter
  renderQuote (text, index, removed, id) {
    const isRemoved = !!removed
    // if there is an existing quote with the ID, grab it
    let quote = this.matchingExistingQuote(text, index)
    if (quote !== undefined) {
      // Update matched to be truthy
      this.existingQuotes[String(index)].matched = true
    } else {
      // otherwise, this quote wasn't found so build a new quote
      quote = {
        matched: true,
        text: text,
        id: String(new Date().getTime()), // simple ID generation
        removed: isRemoved
      }
    }
    // If this is the first quote, prepend it to the quoteFields

    // otherwise, put it after the element with the preceding index
  }

  matchingExistingQuote ({ text, refNumber }) {
    // get entries ([k, v]) that aren't already matched
    const potentialMatches = Object.entries(this.existingQuotes).filter(entry => !entry[1].matched)
    // Scores is an array sorted by the score (high to low), with entry index
    const scores = _.sortBy(potentialMatches.map((entry) => {
      return { index: parseInt(entry[0], 10), score: this.similarity(text, entry[1].text) }
    }), 'score')
    // log.debug(potentialMatches)
    // log.debug(index)
    let matchIndex = null
    for (const score of scores) {
      log.debug(score, `${index} ${index === score.index} - ${score.index} - ${score.score}`)
      // Put our finger on the scale if the index of the potential match is the same as the index of this quote
      if (index === score.index && score.score > 0.2) {
        log.debug('in here')
        matchIndex = index
        break
      }
    }
    log.debug(matchIndex)
    // Put our finger on the scale if the index of the potential match is the same as the index of this quote
    // if (this.blockQuotes.length == 1 && Object.keys(potentialMatches).length == 1 &&
    //   scores[0].score > 0) {
    //   log.debug(scores[0])
    //   return potentialMatches['0']
    // }

    return matchIndex === null ? false : potentialMatches[matchIndex]
  }

  // I'd prefer to use lodash throttle - BUT - I don't know how to bind the context correctly
  // So I'm using this throttle, until I figure out how to bind
  // h/t to https://towardsdev.com/debouncing-and-throttling-in-javascript-8862efe2b563
  throttle (func, limit) {
    let lastFunc
    let lastRan
    return () => {
      const context = this
      const args = arguments
      if (!lastRan) {
        func.apply(context, args)
        lastRan = Date.now()
      } else {
        clearTimeout(lastFunc)
        lastFunc = setTimeout(function () {
          if (Date.now() - lastRan >= limit) {
            func.apply(context, args)
            lastRan = Date.now()
          }
        }, limit - (Date.now() - lastRan))
      }
    }
  }

  // levenstein matching (TODO: improve)
  // h/t https://stackoverflow.com/questions/10473745/compare-strings-javascript-return-of-likely
  similarity (s1, s2) {
    let longer = s1
    let shorter = s2
    if (s1.length < s2.length) {
      longer = s2
      shorter = s1
    }
    const longerLength = longer.length
    if (longerLength === 0) {
      return 1.0
    }
    return (
      (longerLength - this.editDistance(longer, shorter)) / parseFloat(longerLength)
    )
  }

  editDistance (s1, s2) {
    s1 = s1.toString().toLowerCase().trim() // should already be trimmed, but just in case
    s2 = s2.toString().toLowerCase().trim() // should already be trimmed, but just in case

    const costs = new Array()
    for (let i = 0; i <= s1.length; i++) {
      let lastValue = i
      for (let j = 0; j <= s2.length; j++) {
        if (i === 0) costs[j] = j
        else {
          if (j > 0) {
            let newValue = costs[j - 1]
            if (s1.charAt(i - 1) !== s2.charAt(j - 1)) {
              newValue = Math.min(Math.min(newValue, lastValue), costs[j]) + 1
            }
            costs[j - 1] = lastValue
            lastValue = newValue
          }
        }
      }
      if (i > 0) costs[s2.length] = lastValue
    }
    return costs[s2.length]
  }
}

// Previous stuff...
// looksLikeMatch (quote, quoteEl) {
//   $quoteEl = $(quoteEl)
//   // Make sure it isn't processed
//   if (!$quoteEl.hasClass('unprocessed')) {
//     log.debug('has class!!!')
//     return false
//   }
//   return true
// }

// updateBlockquote (text, index) {
//   const regexp = /(^|\n)\s*>/
//   const quoteText = text.replace(regexp, '')

//   let quoteMatchIndex = null

//   // // If there is only one block quote, assume this is it.
//   // if (window.blockQuotes.length == 1 && index == 0 && ) {
//   //   quoteMatchIndex = index;
//   // }
//   if ($('#quoteFields .quote-field.unprocessed').length) {
//     log.debug('ffffff')
//     // First, check if the index matched quote field matches and set it if so.
//     if ($('#quoteFields .quote-field')[index].length) {
//       // Might want to make this match loser if this is the last quote in the argument
//       log.debug(`quote field index!! ${index}`)
//       if (window.looksLikeMatch($('#quoteFields .quote-field')[index])) {
//         quoteMatchIndex = index
//       }
//     }
//   }

//   // test quoteMatches - one of the existing quote elements matches the text closely enough
//   let $quoteField = null
//   log.debug(
//     `blockquote length: ${window.blockQuotes.length} index: ${index} quoteMatchIndex: ${quoteMatchIndex}`
//   )
//   if (quoteMatchIndex !== null) {
//     log.debug('matched something!')
//     $quoteField = $($('#quoteFields .quote-field')[index])
//     $quoteField.removeClass('unprocessed')
//     $quoteField.find('.quote-text').text(quoteText)
//   } else {
//     log.debug('new field')
//     const field =
//       index === 0 ? $('#quoteFields') : $('#quoteFields .quote-field')[index]
//     // log.debug(field);

//     field.prepend(
//       `<div class="quote-field"><p class="quote-text">${quoteText}</p></div>`
//     )
//   }
// }
