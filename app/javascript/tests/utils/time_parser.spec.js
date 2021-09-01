import log from '../../utils/log'
import TimeParser from '../../utils/time_parser'

window.localTimezone = 'America/Los_Angeles' // For consistency in testing
const timeParser = new TimeParser()

test('time_parser returns invalid date for unparseable time', () => {
  const target = '<span title="Invalid date">Invalid date</span>'

  expect(timeParser.localizedTimeHtml('   ', {})).toBe(target)
  expect(timeParser.localizedTimeHtml('ADF*(asdcx89z89xcv', {})).toBe(target)
})

test('time_parser formats time from years ago', () => {
  const target = '<span title="2019-06-03 11:55:14 am">2019-06-03</span>'

  expect(timeParser.localizedTimeHtml('2019-06-03T11:55:14-0700', {})).toBe(
    target
  )
  // Also converts unix timestamps
  expect(timeParser.localizedTimeHtml('1559588114', {})).toBe(target)
  // and should work for integer timestamps
  expect(timeParser.localizedTimeHtml(1559588114, {})).toBe(target)
})

test('time_parser formats time from years ago, preciseTime', () => {
  expect(timeParser.localTimezone).toBe('America/Los_Angeles')
  expect(timeParser.localizedTimeHtml(1559588114, { preciseTime: true })).toBe(
    '<span title="2019-06-03 11:55:14 am">2019-06-03 <span class="less-strong">11:55am</span></span>'
  )

  expect(
    timeParser.localizedTimeHtml(1559588114, {
      preciseTime: true,
      includeSeconds: true
    })
  ).toBe(
    '<span title="2019-06-03 11:55:14 am">2019-06-03 <span class="less-strong">11:55:<small>14</small> am</span></span>'
  )

  // with a different timezone - Doesn't work because moment.tz.setDefault. TODO: make it actually work
  // timeParser.localTimezone = "America/Chicago";
  // expect(timeParser.localTimezone).toBe("America/Chicago");
  // console.log(timeParser.localTimezone);
  // expect(timeParser.localizedTimeHtml(1559588114, { preciseTime: true })).toBe(
  //   '<span title="2019-06-03 1:55:14 pm">2019-06-03 <span class="less-strong">1:55pm</span></span>'
  // );
})

test('time_parser from today', () => {
  const timeStamp = timeParser.todayStart.unix() + 42240 // 11:44am
  const tzoffset = -28800000 // PST offset
  const dateString = new Date(Date.now() + tzoffset).toISOString().substring(0, 10)

  expect(timeParser.localizedTimeHtml(timeStamp, {})).toBe(
    `<span title="${dateString} 11:44:00 am">11:44am</span>`
  )

  // With includeSeconds and withPreposition
  expect(
    timeParser.localizedTimeHtml(timeStamp, {
      includeSeconds: true,
      withPreposition: true
    })
  ).toBe(
    `<span title="${dateString} 11:44:00 am"> at 11:44:<small>00</small> am</span>`
  )
  // With preciseTime
  expect(timeParser.localizedTimeHtml(timeStamp, { preciseTime: true })).toBe(
    `<span title="${dateString} 11:44:00 am">11:44am</span>`
  )
  // With singleFormat
  expect(timeParser.localizedTimeHtml(timeStamp, { singleFormat: true })).toBe(
    `<span title="${dateString} 11:44:00 am">${dateString}</span>`
  )
})

test('time_parser from yesterday', () => {
  const timeStamp = timeParser.todayStart.unix() - 15120 // 7:48pm
  const dateString = timeParser.yesterdayStart.format('YYYY-MM-DD')

  expect(timeParser.localizedTimeHtml(timeStamp, {})).toBe(
    `<span title="${dateString} 7:48:00 pm">Yesterday 7:48pm</span>`
  )

  // With preciseTime
  expect(timeParser.localizedTimeHtml(timeStamp, { preciseTime: true })).toBe(
    `<span title="${dateString} 7:48:00 pm">Yesterday 7:48pm</span>`
  )
  // With singleFormat
  expect(timeParser.localizedTimeHtml(timeStamp, { singleFormat: true })).toBe(
    `<span title="${dateString} 7:48:00 pm">${dateString}</span>`
  )
})
