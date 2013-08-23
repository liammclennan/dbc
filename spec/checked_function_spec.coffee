
describe 'type checked function', ->
    o =
        a: [{validator: 'type', args: ['string']}]

    it 'should still work', ->
        f = dbc.wrap((thing)->
            "pre-#{thing}-suf"
        , {thing: o})
        expect(f 'middle').toBe('pre-middle-suf')

    it 'should fail if the first argument does not match its type', ->
        f = dbc.wrap((thing) ->
            "pre-#{thing}-suf"
        , {thing: o})
        expect(-> f 2).toThrow()

    it 'should allow extra arguments', ->
        f = dbc.wrap((thing, second, third) ->
            "pre-#{thing}-suf"
        , {thing: o})
        expect(f 'mid', 2, 3).toBe('pre-mid-suf')

    it 'should not allow extra specs', ->
        f = dbc.wrap((thing) ->
            "pre-#{thing}-suf"
        , {thing: o, second: {b: [validator: 'required']}})
        expect(-> f 'middle').toThrow();
