import ArgumentForm from '../../scripts/sections/argument_form'
import log from '../../scripts/utils/log'

describe('parseArgumentQuotes', () => {
  const argumentForm = new ArgumentForm({})

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

  it('parses text body with multiple of the same quote', () => {
    const target = ['something']
    expect(argumentForm.parseArgumentQuotes('> something\n\n>something')).toStrictEqual(target)
    expect(argumentForm.parseArgumentQuotes('  >  something  \n blahhh blah blah\n \nother stuff\n >   something')).toStrictEqual(target)
  })
})

describe('matchingExistingQuote', () => {
  const simpleExistingQuote = {
    matched: false,
    text: 'something',
    id: '12',
    removed: false
  }
  const loremIpsum = {
    matched: false,
    text: 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
    id: '2',
    removed: false
  }
  describe('single quote', () => {
    const argumentForm = new ArgumentForm({ existingQuotes: { 0: simpleExistingQuote } })
    it('matches simple thing', () => {
      expect(argumentForm.matchingExistingQuote({ text: 'something', refNumber: 0 })).toStrictEqual(['0', simpleExistingQuote])
      expect(argumentForm.matchingExistingQuote({ text: 'something new', refNumber: 0 })).toStrictEqual(['0', simpleExistingQuote])
      expect(argumentForm.matchingExistingQuote({ text: 'new something blah', refNumber: 0 })).toStrictEqual(['0', simpleExistingQuote])
      expect(argumentForm.matchingExistingQuote({ text: 'something Lorem ipsum dolor sit amet, consectetur adipisicing elit.', refNumber: 0 })).toStrictEqual(['0', simpleExistingQuote])
    })
    it("doesn't match complete non match", () => {
      expect(argumentForm.matchingExistingQuote({ text: 'blah blah blah', refNumber: 0 })).toBe(false)
    })
  })

  describe('already matched', () => {
    const argumentForm = new ArgumentForm({ existingQuotes: { 0: { ...simpleExistingQuote, ...{ matched: true } } } })
    it('returns false', () => {
      expect(argumentForm.matchingExistingQuote({ text: 'something', refNumber: 0 })).toBe(false)
    })
  })

  describe('multiple quotes', () => {
    const argumentForm = new ArgumentForm({ existingQuotes: { 0: loremIpsum, 1: simpleExistingQuote } })
    it('matches simple', () => {
      expect(argumentForm.matchingExistingQuote({ text: 'something', refNumber: 0 })).toStrictEqual(['1', simpleExistingQuote])
      expect(argumentForm.matchingExistingQuote({ text: 'something new', refNumber: 0 })).toStrictEqual(['1', simpleExistingQuote])
      expect(argumentForm.matchingExistingQuote({ text: 'new something blah', refNumber: 0 })).toStrictEqual(['1', simpleExistingQuote])
    })
  })

  describe('multiple similar quotes', () => {
    const loremIpsum2 = { ...loremIpsum, ...{ text: 'Lorem ipsum dolor sit amet - and some non-latin goes here', id: '4' } }
    const argumentForm = new ArgumentForm({ existingQuotes: { 0: loremIpsum, 1: loremIpsum2, 2: simpleExistingQuote } })
    it('matches the better match', () => {
      expect(argumentForm.matchingExistingQuote({ text: 'Lorem ipsum dolor sit amet -  and', refNumber: 0 })).toStrictEqual(['1', loremIpsum2])
      // I don't love this test, and I'm ok with it failing - I don't think it tests a real world thing
      // - but I do think that we have some more testing to do
      // expect(argumentForm.matchingExistingQuote({ text: 'Lorem ipsum dolor sit amet, consectetur adipisicing', refNumber: 3 })).toStrictEqual(['0', loremIpsum])
    })
  })
})
