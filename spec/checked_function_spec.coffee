dbc = require '../dbc'

describe 'type checked function', ->
    o =
        a: [{validator: 'type', args: ['string']}]

    it 'should still work', ->
        f = dbc.wrap((thing)->
            "pre-#{thing}-suf"
        , {})
        expect(f 'middle').toBe('pre-middle-suf')

    it 'should bind "this" properly', ->
        o =
            a: 5
            b: dbc.wrap((n)->
                @a + n
            , {})
        expect(o.b(64)).toBe(69)

    it 'should fail if the first argument does not match its type', ->
        f = dbc.wrap((thing) ->
            "pre-#{thing}-suf"
        , {"0": [{validator:'type',args:['string']}]})
        expect(-> f 2).toThrow()

    it 'should fail if the second argument does not match its type', ->
        f = dbc.wrap((n1,n2) ->
            n1 + n2
        , {
            "0": [{validator:'type',args:['number']}],
            "1": [{validator:'type',args:['number']}]
        })
        expect(-> f 2, {t: 3}).toThrow()

    it 'should allow extra arguments', ->
        f = dbc.wrap((thing, second, third) ->
            "pre-#{thing}-suf"
        , {0: [{validator:'type',args:['string']}]})
        expect(f 'mid', 2, 3).toBe('pre-mid-suf')

    it 'should not allow extra specs', ->
        f = dbc.wrap((thing) ->
            "pre-#{thing}-suf"
        , {0: [{validator:'required'}], 1: [{validator: 'string?'}]})
        expect(-> f 'middle').toThrow()

    describe 'checking the return value', ->
        describe 'with matching validator', ->
            f = null
            beforeEach ->
                inner = (thing) ->
                    "pre-#{thing}-suf"
                f = dbc.wrap(inner, null, [{validator:'type',args:['string']}])
            
            it 'should pass', ->
                expect(f 'foo').toBe('pre-foo-suf')

        describe 'with failing validator', ->
            f = null
            beforeEach ->
                inner = (thing) ->
                    "pre-#{thing}-suf"
                f = dbc.wrap(inner, null, [{validator:'type',args:['number']}])
            
            it 'should throw', ->
                expect(-> f 'foo').toThrow()

        describe 'with nullable validator', ->
            f = null
            beforeEach ->
                inner = (thing) ->
                    null
                f = dbc.wrap(inner, null, [{validator:'type',args:['number?']}])
            
            it 'should pass', ->
                expect(f 'foo').toBeNull()
    
