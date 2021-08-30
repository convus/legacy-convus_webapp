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

  it('parses multi line block quotes', () => {
    const target = ['multi line message']
    expect(argumentForm.parseArgumentQuotes('> multi line message ')).toStrictEqual(target)
    expect(argumentForm.parseArgumentQuotes('> multi\n> line   \n> message ')).toStrictEqual(target)
    expect(argumentForm.parseArgumentQuotes('Some stuff goes here\n > multi   \n >    line\n > message     \n\n\nAnd then more stuff')).toStrictEqual(target)
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
    prevIndex: 0,
    matched: false,
    text: 'something',
    id: '12',
    removed: false
  }
  const loremIpsum = {
    prevIndex: 1,
    matched: false,
    text: 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
    id: '2',
    removed: false
  }
  describe('single quote', () => {
    const argumentForm = new ArgumentForm({ existingQuotes: { 0: simpleExistingQuote } })
    it('matches simple thing', () => {
      const target = { ...simpleExistingQuote, ...{ prevIndex: 0 } }
      expect(argumentForm.matchingExistingQuote({ text: 'something', index: 0 })).toStrictEqual(target)
      expect(argumentForm.matchingExistingQuote({ text: 'something new', index: 0 })).toStrictEqual(target)
      expect(argumentForm.matchingExistingQuote({ text: 'new something blah', index: 0 })).toStrictEqual(target)
      expect(argumentForm.matchingExistingQuote({ text: 'something Lorem ipsum dolor sit amet, consectetur adipisicing elit.', index: 0 })).toStrictEqual(target)
    })
    it("doesn't match complete non match", () => {
      expect(argumentForm.matchingExistingQuote({ text: 'blah blah blah', index: 0 })).toBe(undefined)
    })
  })

  describe('already matched', () => {
    const argumentForm = new ArgumentForm({ existingQuotes: { 0: { ...simpleExistingQuote, ...{ matched: true } } } })
    it('returns false', () => {
      expect(argumentForm.matchingExistingQuote({ text: 'something', index: 0 })).toBe(undefined)
    })
  })

  describe('multiple quotes', () => {
    const argumentForm = new ArgumentForm({ existingQuotes: { 0: simpleExistingQuote, 1: loremIpsum } })
    it('matches simple', () => {
      expect(argumentForm.matchingExistingQuote({ text: 'something', index: 1 })).toStrictEqual(simpleExistingQuote)
      expect(argumentForm.matchingExistingQuote({ text: 'something new', index: 1 })).toStrictEqual(simpleExistingQuote)
      expect(argumentForm.matchingExistingQuote({ text: 'new something blah', index: 1 })).toStrictEqual(simpleExistingQuote)
    })
  })

  describe('existing quote', () => {
    const closeMatchText = 'Lorem ipsum dolor sit amet - and'
    const loremIpsum0 = { ...loremIpsum, ...{ prevIndex: 0 } }
    const argumentForm = new ArgumentForm({ existingQuotes: { 0: loremIpsum0 }, blockQuotes: [closeMatchText, loremIpsum0.text] })
    it('does not match the later exact match', () => {
      // Make sure that the similarity is at least the similarity required for matching things of the same index
      expect(argumentForm.similarity(closeMatchText, loremIpsum0.text)).toBeGreaterThan(0.2)
      // This is specifically relevant when pasting in quotes before the existing quote
      expect(argumentForm.matchingExistingQuote({ text: closeMatchText, index: 0 })).toBe(undefined)
      expect(argumentForm.matchingExistingQuote({ text: loremIpsum0.text, index: 1 })).toStrictEqual(loremIpsum0)
    })
  })

  describe('multiple similar quotes', () => {
    const loremIpsum2 = { ...loremIpsum, ...{ text: 'Lorem ipsum dolor sit amet - and some non-latin goes here', id: '4', prevIndex: 2 } }
    it('matches the better match', () => {
      const argumentForm = new ArgumentForm({ existingQuotes: { 1: simpleExistingQuote, 0: loremIpsum, 2: loremIpsum2 } })

      expect(argumentForm.matchingExistingQuote({ text: 'Lorem ipsum dolor sit amet -  and', index: 0 })).toStrictEqual(loremIpsum2)
      // It's an exact match for one of the quotes - but has additional things. It should match
      expect(argumentForm.matchingExistingQuote({ text: 'Lorem ipsum dolor sit amet - and some non-latin goes here plus some extra words and some more things!!', index: 0 })).toStrictEqual(loremIpsum2)
      // I don't love this test, and I'm ok with it failing - I don't think it tests a real world thing
      // - but I do think that we have some more testing to do
      // expect(argumentForm.matchingExistingQuote({ text: 'Lorem ipsum dolor sit amet, consectetur adipisicing', index: 3 })).toStrictEqual(loremIpsum)
    })

    it('maintains the exact match', () => {
      const argumentForm = new ArgumentForm({ existingQuotes: { 0: loremIpsum, 1: loremIpsum2, 2: simpleExistingQuote } })
      // This is specifically useful when pasting a new quote in the text. Other quotes, even if they are similar, shouldn't rearrange if there is an exact match
      // NOTE: this test is passing, but this is a problem when actually doing stuff. :(
      expect(argumentForm.matchingExistingQuote({ text: 'Lorem ipsum dolor sit amet - and some non-latin goes ', index: 0 })).toStrictEqual(loremIpsum2)
      expect(argumentForm.matchingExistingQuote({ text: loremIpsum.text, index: 1 })).toStrictEqual(loremIpsum)
    })
  })

  describe('much longer quote', () => {
    const argumentForm = new ArgumentForm({ existingQuotes: { 0: simpleExistingQuote, 1: loremIpsum } })
    it('matches the', () => {
      expect(argumentForm.matchingExistingQuote({ text: 'Lorem ipsum dolor sit amet, consectetur', index: 1 })).toStrictEqual(loremIpsum)
    })
  })
})
