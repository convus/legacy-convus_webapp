import ArgumentForm from '../../scripts/sections/argument_form'
import log from '../../scripts/utils/log'

describe('parseArgumentQuotes', () => {
  const argumentForm = new ArgumentForm()

  it('parses text body without quotes', () => {
    const target = []

    expect(argumentForm.parseArgumentQuotes('   ')).toStrictEqual(target)
    expect(argumentForm.parseArgumentQuotes(' \n\nasdfasdf\n\nasdfasdf ')).toStrictEqual(target)

    expect(argumentForm.parseArgumentQuotes('>  \n')).toStrictEqual(target)
    expect(argumentForm.parseArgumentQuotes('>  \n\n > \n\n>')).toStrictEqual(target)
  })

  it('parses text body with single quote', () => {
    const target = ['something']
    expect(argumentForm.parseArgumentQuotes('> something')).toStrictEqual(target)
    expect(argumentForm.parseArgumentQuotes('  >  something  \n\nother stuff')).toStrictEqual(target)
    expect(argumentForm.parseArgumentQuotes('\n> something')).toStrictEqual(target)
    expect(argumentForm.parseArgumentQuotes('\nsomething else\nAnd MORE things\n\n\n  >    something \n\nother things')).toStrictEqual(target)
  })

  it('parses text body with multiple quotes', () => {
    const target = ['something', 'something else']
    expect(argumentForm.parseArgumentQuotes('> something\n\n>something else')).toStrictEqual(target)
    expect(argumentForm.parseArgumentQuotes('  >  something  \n blahhh blah blah\n \nother stuff\n >   something else')).toStrictEqual(target)
  })
})
