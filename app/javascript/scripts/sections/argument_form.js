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
    this.renderedQuoteIds = []
    this.previewOpen
    // maybe should be based on the power of the device that is editing?
    this.throttleLimit = throttleLimit || 500
  }

  // init is called when loaded on the page - and not in testing
  init () {
    // I THINK we always want to process the text to instantiate the variables
    this.updateArgumentQuotes()

    // For testing purposes, automatically select the argument field - but actually this is nice?
    $('#argument_text').focus()

    // Setup preview after inital parse, so that it doesn't initially collapse
    this.updatePreview()

    // Start updating quotes when argument changes
    $('#argument_text').on(
      'keydown keyup update blur',
      this.throttle(this.updateArgumentQuotes, this.throttleLimit)
    )
  }

  parseArgumentQuotes (text) {
    // Regex for matching lines that are blockquotes
    const matchRegexp = /^\s*>/
    // regex for replacing the "> " from the quotes
    const replaceRegexp = /^\s*>\s*/

    const matchingLines = []
    let lastQuoteLine
    text.split('\n').forEach((line, index) => {
      if (line.match(matchRegexp)) {
        // remove the >, trim the string
        let quoteText = line.replace(replaceRegexp, '').trim()
        // We need to group consecutive lines, because that's how markdown parses
        // So check if the last line was a quote and if so, update it
        if (lastQuoteLine === index - 1) {
          quoteText = [matchingLines.pop(), quoteText].join(' ')
        }
        matchingLines.push(quoteText)
        lastQuoteLine = index
      }
    })
    // - remove duplicates
    // - ignore any empty quotes
    return _.uniq(matchingLines).filter(str => str.length > 0)
  }

  parseExistingQuotes () {
    const existingQuotes = {}

    $('#quoteFieldsWrapper .quote-field').each(function (index) {
      const $this = $(this)

      existingQuotes[String(index)] = {
        matched: false,
        text: $this.find('.quote-text').text(),
        url: $this.find('.url-field').val(),
        id: this.id.replace('quoteId-', ''),
        prevRef: index,
        newQuote: $this.hasClass('newQuote'),
        removed: $this.hasClass('removedQuote')
      }
    })

    return existingQuotes
  }

  updatePreview () {
    // If undefined, set up preview
    if (this.previewOpen == undefined) {
      this.previewOpen = $('#argumentPreview').length
      if (this.previewOpen) {
        window.argumentText = $('#argument_text').val()
      }
      return
    }
    if (window.argumentText !== $('#argument_text').val()) {
      $('#argumentPreview').collapse('hide')
      $('#saveToPreview').collapse('show')
      this.previewOpen = false
    }
  }

  updateArgumentQuotes () {
    const newBlockQuotes = this.parseArgumentQuotes(
      $('#argument_text').val()
    )
    if (this.previewOpen) { this.updatePreview() }
    // In additional to throttling - if the quotes haven't changed, don't process
    if (_.isEqual(this.blockQuotes, newBlockQuotes)) { return }
    // TODO: improve. We were re-processing before finishing rendering (and therefor existingQuotes was blank)
    // we may want to rerun later if we're still processing now (via setTimeout)
    if (this.processing) { return }

    this.processing = true
    this.blockQuotes = newBlockQuotes
    this.existingQuotes = this.parseExistingQuotes()
    this.renderedQuoteIds = []

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

    $('#quoteFieldsWrapper .quote-field').each(function () {
      const id = this.id.replace('quoteId-', '')
      // Could do something better than get via window, but - good enough for now
      if (!window.argumentForm.renderedQuoteIds.includes(id)) {
        this.remove() // remove because it shouldn't be rendered anymore!
      }
    })
    this.processing = false
    this.updateSubmitForApproval()
  }

  updateQuote ({ text, index, removedQuote }) {
    let quote
    // Unless quote was passed in, find or create the quote
    if (removedQuote !== undefined) {
      quote = _.merge(removedQuote, { removed: true, matched: true })
    } else {
      quote = this.matchingExistingQuote({ text: text, refNumber: index })
      if (quote) {
      // If quote exists, merge in the new text, mark it not removed and matched
        quote = _.merge(quote, { text: text, matched: true, removed: false })
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
        removed: false,
        newQuote: true
      }
    }
    // Add quote ID to rendered array
    this.renderedQuoteIds.push(quote.id)
    const selector = quote.removed ? '#quoteFieldsRemoved' : '#quoteFields'
    // TODO: stop using jQuery here
    const $el = $(`${selector} #quoteId-${quote.id}`)
    // If the element exists and is in the same position and is still around, update the quote
    if ($el.length && quote.prevRef === index) {
      $el.find('.quote-text').text(text)
      $el.find(`#argument_argument_quotes_attributes_${quote.id}_text`).val(text)
    } else {
      // Otherwise, we rerender the element.
      // TODO: improve handling - move things around if possible, instead of always rerendering
      if ($el.length) { $el.remove() }
      $(selector).append(this.quoteHtml(index, quote))
    }
    // Remove the opposite removed state quote (e.g. remove existing removed quotes)
    $(`${quote.removed ? '#quoteFields' : '#quoteFieldsRemoved'} #quoteId-${quote.id}`).remove()
  }

  // NOTE: This is duplicated by _argument_quote.html.erb
  quoteHtml (refNumber, quote) {
    // Only include the ID input if quote already exists
    const idInput = quote.newQuote ? '' : `<input type="hidden" name="argument[argument_quotes_attributes][${quote.id}][id]" id="argument_argument_quotes_attributes_${quote.id}_id" value="${quote.id}">`
    return `<div id="quoteId-${quote.id}" class="quote-field ${quote.removed ? 'removedQuote' : ''} ${quote.newQuote ? 'newQuote' : ''}">
      <input type="hidden" name="argument[argument_quotes_attributes][${quote.id}][ref_number]" id="argument_argument_quotes_attributes_${quote.id}_ref_number" value="${refNumber}">
      <input type="hidden" name="argument[argument_quotes_attributes][${quote.id}][removed]" id="argument_argument_quotes_attributes_${quote.id}_removed" value="${quote.removed}">
      <input type="hidden" name="argument[argument_quotes_attributes][${quote.id}][text]" id="argument_argument_quotes_attributes_${quote.id}_text" value="${quote.text}">
      ${idInput}
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

  updateSubmitForApproval () {
    // If there isn't a submit for approval button, our job is done
    if (!$('#submitForApproval').length) { return }
    // disable unless there is a quote
    if ($('#quoteFields .quote-field').length > 0) {
      $('#submitForApproval').attr('disabled', false)
      $('#submitForApproval').removeClass('disabled')
      $('#quoteRequired').collapse('hide')
    } else {
      // There isn't a quote, so let them know they need one
      $('#submitForApproval').attr('disabled', true)
      $('#submitForApproval').addClass('disabled')
      $('#quoteRequired').collapse('show')
    }
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

    const costs = []
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
