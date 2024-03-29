// NOTE: full disclosure - I have no idea what the best practices are for structuring JS
// I'm just winging it. sry

import TimeParser from './utils/time_parser'
// import log from './utils/log'
import LoadFancySelects from './utils/load_fancy_selects.js'
import PeriodSelector from './utils/period_selector.js'

// And also include chartkick
import Chartkick from 'chartkick'
import Chart from 'chart.js'

import ExplanationForm from '../scripts/sections/explanation_form.js'
import AdminBase from '../scripts/sections/admin_base.js'

window.Chartkick = Chartkick
Chartkick.addAdapter(Chart)

$(document).on('turbolinks:load', function () {
  if (!window.timeParser) {
    window.timeParser = new TimeParser()
  }
  window.timeParser.localize()
  // Period selector
  if ($('#timeSelectionBtnGroup').length) {
    const periodSelector = PeriodSelector()
    periodSelector.init()
  }

  if ($('#explanationForm').length) {
    window.explanationForm = new ExplanationForm({})
    window.explanationForm.init()
  }

  if ($('#adminNavbar').length) {
    window.adminBase = new AdminBase({})
    window.adminBase.init()
  }

  $('.addQueryParam').on('click', (e) => {
    const $target = $(e.target)
    const key = $target.attr('data-querykey')
    const value = $target.attr('data-queryvalue')

    const urlParams = new URLSearchParams(window.location.search)
    urlParams.set(key, value)
    const newUrl = new URL(window.location.href)
    newUrl.search = urlParams
    // Only add the query string (and modify the browser history) if it's different
    if (window.location.href !== newUrl.href) {
      // Maybe should be replaceState rather than pushState (to not add to the browser history) - but it breaks turbolinks
      window.history.pushState(null, '', newUrl.href)
    }
  })

  // And load fancy selects after everything, in case something added more fancy selects
  LoadFancySelects()
})
