import log from '../utils/log'
import _ from 'lodash' // TODO: only import the parts needed

// TODO: make less dependent on jquery
export default class ArgumentForm {
  // Enable passing in, primarily for testing
  constructor ({ blockQuotes, existingQuotes, throttleLimit }) {
    this.processing = false
    this.blockQuotes = blockQuotes
    this.existingQuotes = existingQuotes
    this.removedQuotes = []
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

    // For testing purposes, automatically select the argument field
    $('#argument_text').focus()

    // log.debug(this.existingQuotes)

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

    $('#quoteFieldsWrapper .quote-field').each(function (index) {
      const $this = $(this)

      existingQuotes[String(index)] = {
        matched: false,
        text: $this.find('.quote-text').text(),
        url: $this.find('.url-field').val(),
        id: $this.find('.hidden-id-field').val(),
        prevRef: index,
        removed: $this.hasClass('removedQuote')
      }
    })

    return existingQuotes
  }

  updateArgumentQuotes () {
    const newBlockQuotes = this.parseArgumentQuotes(
      $('#argument_text').val()
    )
    // In additional to throttling - if the quotes haven't changed, don't process
    if (_.isEqual(this.blockQuotes, newBlockQuotes)) { return }
    // TODO: improve. We were re-processing before finishing rendering (and therefor existingQuotes was blank)
    // we may want to rerun this later if we're still processing
    if (this.processing) { return }

    this.processing = true
    this.blockQuotes = newBlockQuotes
    this.existingQuotes = this.parseExistingQuotes()

    // TODO: move around instead of just removing
    $('#quoteFieldsWrapper .quote-field').remove()
    this.blockQuotes.forEach((text, index) => {
      this.updateQuote({ text: text, index: index })
    })

    // For any unmatched existing quotes that have urls, sort them by ID, update them to be removed - and render them
    // (we ignore non-url quotes, because who cares, we don't need to save them)
    this.removedQuotes = _.sortBy(Object.values(this.existingQuotes).filter(quote => !quote.matched && quote.url.length), 'prevRef')
    if (this.removedQuotes.length) {
      $('#quoteFieldsRemoved').collapse('show')
      this.removedQuotes.forEach((quote, index) => this.updateQuote({ removedQuote: quote }))
    } else {
      $('#quoteFieldsRemoved').collapse('hide')
    }
    this.processing = false
  }

  updateQuote ({ text, index, removedQuote }) {
    let quote
    // Unless quote was passed in, find or create the quote
    if (removedQuote !== undefined) {
      quote = _.merge(removedQuote, { removed: true, matched: true })
    } else {
      quote = this.matchingExistingQuote({ text: text, refNumber: index })
      if (quote) {
      // If quote exists, merge in the new text, mark it not removed
        quote = _.merge(quote, { text: text, matched: true, removed: false })
      // And make the quote matched
      }
    }

    if (quote) {
      // If the quote is one of the existingQuotes, update the existing quote
      const existingIndex = quote.prevRef || _.findIndex(this.existingQuotes, ['id', quote.id])
      if (existingIndex) {
        this.existingQuotes[existingIndex] = quote
      }
    } else {
      // this quote wasn't found so build a new quote
      // log.debug(`QUOTE NOT FOUND!!! ${text}`)
      quote = {
        matched: true,
        text: text,
        id: String(new Date().getTime()), // simple ID generation
        url: '',
        removed: false
      }
    }

    // TODO: move around/detach or something, rather than just rerendering
    const selector = quote.removed ? '#quoteFieldsRemoved' : '#quoteFields'
    $(selector).append(this.quoteHtml(index, quote))
  }

  // NOTE: refNumber for deleted quotes should be null - and maybe they shouldn't actually be form elements?
  // ALSO: quote text should maybe be a hidden field? - probably not actually
  quoteHtml (refNumber, quote) {
    return `<div class="quote-field ${quote.removed ? 'removedQuote' : ''}">
      <input type="hidden" name="argument[argument_quotes_attributes][${quote.id}][id]" id="argument_argument_quotes_attributes_${quote.id}_id" class="hidden-id-field" value="${quote.id}">
      <input type="hidden" name="argument[argument_quotes_attributes][${quote.id}][ref_number]" id="argument_argument_quotes_attributes_${quote.id}_ref_number" value="${refNumber}">
      <p class="quote-text">${quote.text}</p>
      <div class="form-group">
        <input type="url" name="argument[argument_quotes_attributes][${quote.id}][url]" id="argument_argument_quotes_attributes_${quote.id}_url" value="${quote.url}" class="form-control url-field" placeholder="Quote URL source">
      </div>
    </div>`
  }

  matchingExistingQuote ({ text, refNumber }) {
    // get unmatched quotes
    const potentialMatches = Object.values(this.existingQuotes).filter(quote => !quote.matched)
    let match

    // Match if a potentialMatch text is a substring of the text (or the text is a substring of a potentialMatch)
    for (const pMatch of potentialMatches) {
      if (text.includes(pMatch.text) || pMatch.text.includes(text)) {
        // log.debug(`substring match: ${pMatch.text} - ${text}`)
        match = pMatch
      }
    }
    // If not a substring, we use levenstein
    if (match === undefined) {
      // Scores is an array sorted by the score (high to low)
      const scores = _.sortBy(potentialMatches.map((pMatch) => {
        return { pMatch: pMatch, score: this.similarity(text, pMatch.text) }
      }), 'score')
      // Iterate through the scores, from high score to low score, use the first match
      for (const score of _.reverse(scores)) {
        // log.debug(`score.index: ${score.index}, score: ${score.score} --- refNumber: ${refNumber}, text: ${_.truncate(text, { length: 40 })}`)
        // ^ For logging in testing, because iteration
        // Put our finger on the scale if the index of the potential match is the same as the index of this quote
        if (refNumber === score.pMatch.prevRef && score.score > 0.1) {
          match = score.pMatch
          break
        } else if (score.score > 0.3) {
          match = score.pMatch
          break
        }
      }
    }
    return match
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

  // levenstein matching - h/t https://stackoverflow.com/questions/10473745/compare-strings-javascript-return-of-likely
  // TODO: improve for this application
  // Specific improvements: Current algorithm is more influenced by the length of the string than it should be.
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