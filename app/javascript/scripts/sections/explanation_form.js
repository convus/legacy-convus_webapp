import log from '../utils/log'
import _ from 'lodash' // TODO: only import the parts needed

// TODO: make less dependent on jquery
export default class ExplanationForm {
  // Enable passing in, primarily for testing
  constructor ({ blockQuotes, existingQuotes, throttleLimit }) {
    this.processing = false
    this.blockQuotes = blockQuotes || []
    this.existingQuotes = existingQuotes || []
    this.removedQuotes = []
    this.renderedQuoteIds = []
    this.existingText = undefined
    this.previewOpen = false
    // maybe should be based on the power of the device that is editing?
    this.throttleLimit = throttleLimit || 500
  }

  // init is called when loaded on the page - and not in testing
  init () {
    // I THINK we always want to process the text to instantiate the variables
    this.updateExplanationQuotes()

    // Setup preview after inital parse, so that it doesn't initially collapse
    this.previewOpen = $('#explanationPreview').length > 0

    // For testing purposes, automatically select the explanation field - but actually this is nice?
    $('#explanation_text').focus()

    $('#submitForApproval').on('click', (e) => {
      e.preventDefault()
      $('form .loadingSpinner').collapse('show')
      $('.submit-input').addClass('disabled')
      $('.addToGithubField').val('1')
      $('#explanationForm').submit()
    })

    // Start updating quotes when explanation changes
    $('#explanation_text').on(
      'keydown keyup update blur',
      this.throttle(this.updateExplanationQuotes, this.throttleLimit)
    )

    // Set researchKinds here
    this.researchKinds = ($('#citationsBlock').attr('data-citeresearchkinds') || '').split(',')
    $('#citationsBlock').on('change', '.citationKindSelect', (event) => {
      this.updateCitationKind(
        $(event.target).parents('.citationFields')
      )
    })
  }

  updateCitationKind ($fields) {
    const citationKind = $fields.find('.citationKindSelect').val()
    const isResearchKind = this.researchKinds.includes(citationKind)
    // Toggle the kind
    $fields
      .find('.kindResearchField')
      .collapse(isResearchKind ? 'show' : 'hide')
  }

  // NOTE: This is duplicated in Explanation.parse_quotes, in ruby, for flat file importing
  parseExplanationQuotes (text) {
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
        prevIndex: index,
        newQuote: $this.hasClass('newQuote'),
        removed: $this.hasClass('removedQuote')
      }
    })

    return existingQuotes
  }

  updatePreview () {
    log.debug('updating preview')
    // If this hasn't run, collapse it (this should only run if the text has changed)
    this.previewOpen = false
    $('#explanationPreview').collapse('hide')
  }

  updateExplanationQuotes () {
    // If currently processing, skip running
    if (this.processing) { return }

    const newText = $('#explanation_text').val()
    // Don't process if text is unchanged
    if (newText === this.existingText) { return }
    // update the preview if the text has changed
    if (this.previewOpen) { this.updatePreview() }
    this.existingText = newText
    // Previously was skipping processing if quotes hadn't changed, but that seemed to fail for cut and paste sometimes
    // const newBlockQuotes = this.parseExplanationQuotes($('#explanation_text').val())
    // if (_.isEqual(this.blockQuotes, newBlockQuotes)) { return }
    // TODO: improve. We were re-processing before finishing rendering (and therefor existingQuotes was blank)
    // we may want to rerun later if we're still processing now (via setTimeout)
    // log.debug('processing')

    this.processing = true
    this.blockQuotes = this.parseExplanationQuotes($('#explanation_text').val())
    this.existingQuotes = this.parseExistingQuotes()
    this.renderedQuoteIds = []

    this.blockQuotes.forEach((text, index) => {
      this.updateQuote({ text: text, index: index })
    })

    // For any unmatched existing quotes that have urls, sort them by ID, update them to be removed - and render them
    // (we ignore non-url quotes, because who cares, we don't need to save them)
    this.removedQuotes = _.sortBy(Object.values(this.existingQuotes).filter(quote => !quote.matched && quote.url.length), 'prevIndex')
    if (this.removedQuotes.length) {
      $('#quoteFieldsRemoved').collapse('show')
      this.removedQuotes.forEach((quote, index) => this.updateQuote({ removedQuote: quote }))
    } else {
      $('#quoteFieldsRemoved').collapse('hide')
    }

    $('#quoteFieldsWrapper .quote-field').each(function () {
      const id = this.id.replace('quoteId-', '')
      // Could do something better than get via window, but - good enough for now
      if (!window.explanationForm.renderedQuoteIds.includes(id)) {
        this.remove() // remove because it shouldn't be rendered anymore!
      }
    })
    this.processing = false
    this.updateSubmitForApproval()
  }

  updateQuote ({ text, index, removedQuote }) {
    let quote
    // Unless removedQuote was passed in, find or create the quote
    if (removedQuote !== undefined) {
      quote = _.merge(removedQuote, { removed: true, matched: true })
    } else {
      quote = this.matchingExistingQuote({ text: text, index: index })
      if (quote) {
      // If quote exists, merge in the new text, mark it not removed and matched
        quote = _.merge(quote, { text: text, matched: true, removed: false })
      }
    }

    if (quote) {
      // If the quote is one of the existingQuotes, update the existing quote
      const existingIndex = quote.prevIndex || _.findIndex(Object.values(this.existingQuotes), ['id', quote.id])
      if (existingIndex >= 0) {
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
    if ($el.length && quote.prevIndex === index) {
      $el.find('.quote-text').text(text)
      $el.find(`#explanation_explanation_quotes_attributes_${quote.id}_text`).val(text)
      // Also update the Citation
      const $citationQuote = $(`#citationExplanationQuote-${quote.id}`)
      if ($citationQuote.length) {
        $citationQuote.text(text)
        // Also should update the URL for this Citation, if the URL has changed
      }
    } else {
      // Otherwise, we rerender the element.
      // TODO: improve handling - move things around if possible, instead of always rerendering
      if ($el.length) { $el.remove() }
      $(selector).append(this.quoteHtml(index, quote))
    }
    // Remove the opposite removed state quote (e.g. remove existing removed quotes)
    $(`${quote.removed ? '#quoteFields' : '#quoteFieldsRemoved'} #quoteId-${quote.id}`).remove()
  }

  // NOTE: This is duplicated by _explanation_quote.html.erb
  quoteHtml (index, quote) {
    // Only include the ID input if quote already exists
    const idInput = quote.newQuote ? '' : `<input type="hidden" name="explanation[explanation_quotes_attributes][${quote.id}][id]" id="explanation_explanation_quotes_attributes_${quote.id}_id" value="${quote.id}">`
    return `<div id="quoteId-${quote.id}" class="quote-field ${quote.removed ? 'removedQuote' : ''} ${quote.newQuote ? 'newQuote' : ''}">
      <input type="hidden" name="explanation[explanation_quotes_attributes][${quote.id}][ref_number]" id="explanation_explanation_quotes_attributes_${quote.id}_ref_number" value="${index + 1}">
      <input type="hidden" name="explanation[explanation_quotes_attributes][${quote.id}][removed]" id="explanation_explanation_quotes_attributes_${quote.id}_removed" value="${quote.removed}">
      <input type="hidden" name="explanation[explanation_quotes_attributes][${quote.id}][text]" id="explanation_explanation_quotes_attributes_${quote.id}_text" value="${quote.text}">
      ${idInput}
      <blockquote class="quote-text">${quote.text}</blockquote>
      <div class="form-group">
        <input type="url" name="explanation[explanation_quotes_attributes][${quote.id}][url]" id="explanation_explanation_quotes_attributes_${quote.id}_url" value="${quote.url}" class="form-control url-field" placeholder="Quote URL source">
      </div>
    </div>`
  }

  matchingExistingQuote ({ text, index }) {
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
      // get the quotes that are after this quote
      const laterQuotes = this.blockQuotes.slice(index + 1)
      // Scores is an array sorted by the score (high to low)
      const scores = _.sortBy(potentialMatches.map((pMatch) => {
        // If there is quote after this quote in the blockQuote array that matches the text of this potentialMatch exactly,
        // give it a score of zero (important if a quote is pasted in before the existing quote)
        // Otherwise - use levenstein similarity to match
        const score = (laterQuotes.some((i) => i === pMatch.text)) ? 0 : this.similarity(text, pMatch.text)
        return { pMatch: pMatch, score: score }
      }), 'score')
      // Iterate through the scores, from high score to low score, use the first match
      for (const score of _.reverse(scores)) {
        // log.debug(`score.index: ${score.index}, score: ${score.score} --- index: ${index}, text: ${_.truncate(text, { length: 40 })}`)
        // Put our finger on the scale if the index of the potential match is the same as the index of this quote
        if (index === score.pMatch.prevIndex && score.score > 0.1) {
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
