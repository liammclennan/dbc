describe 'dbc type validation', ->
    dbc = require '../dbc'

    describe 'type validation', ->
        describe 'non-nullable type', ->
            describe 'with null value', ->
                spec =
                    a: [{validator:'type', args:['string']}]
                o =
                    a: null

                it 'should fail', ->
                    expect(-> dbc.check o,spec).toThrow()

            describe 'with undefined value', ->
                spec =
                    a: [{validator:'type', args:['string']}]
                o =
                    a: undefined

                it 'should fail', ->
                    expect(-> dbc.check o,spec).toThrow()

            describe 'nullable with null value', ->
                spec =
                    a: [{validator:'type',args:['string?']}]
                o =
                    a: null

                it 'should pass', ->
                    dbc.check o,spec


            describe 'nullable with undefined value', ->
                spec =
                    a: [{validator:'type',args:['string?']}]
                o =
                    a: undefined

                it 'should pass', ->
                    dbc.check o,spec

        describe 'unknown type', ->
            spec =
                a: [{validator:'type', args:['sfsydfsdf']}]
            o =
                a: 'sfasd'

            it 'should fail', ->
                expect(-> dbc.check o,spec).toThrow()

