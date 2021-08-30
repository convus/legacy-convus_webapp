import log from '../utils/log'

export default class AdminBase {
  initAdminSearchSelect () {
    window.initialValue = $('#admin_other_navigation').val()
    // On change, if the change is for something new and is an actual value, redirect to that page
    $('#admin_other_navigation').on('change', e => {
      const newValue = $('#admin_other_navigation').val()
      if (newValue != window.initialValue && newValue.length > 0) {
        location.href = newValue
      }
    })
  }

  init () {
    log.debug('in admin')

    this.initAdminSearchSelect()
  }
}
