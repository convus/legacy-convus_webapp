import ArgumentForm from '../../scripts/sections/argument_form'
import log from '../../scripts/utils/log'

describe('parseArgumentQuotes', () => {
  const argumentForm = new ArgumentForm()

  it('parses text body without quotes', () => {
    const target = []

    // log.debug(`:  "${' '.trim()}" `)

    expect(argumentForm.parseArgumentQuotes('   ')).toStrictEqual(target)
    expect(argumentForm.parseArgumentQuotes(' \n\nasdfasdf\n\nasdfasdf ')).toStrictEqual(target)

    expect(argumentForm.parseArgumentQuotes('>  \n')).toStrictEqual(target)
    expect(argumentForm.parseArgumentQuotes('>  \n\n > \n\n>')).toStrictEqual(target)
  })
})
