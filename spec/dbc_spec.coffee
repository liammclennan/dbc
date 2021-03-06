describe 'dbc', ->
    dbc = require '../dbc'

    describe 'validate range', ->
        spec =
            hscw: [{validator:'range', args:[0,100]}]

        describe 'in range', ->
            it 'should succeed', ->
                for p in [44.99,0,100,-0]
                    result = dbc.validate {hscw: p}, spec
                    expect(result.length).toBe(0)

        describe 'validate invalid percentage', ->
            it 'should fail', ->
                for p in [-10,'cat',100.1]
                    result = dbc.validate {hscw: p}, spec
                    expect(result.length).toBe(1)
                

    describe 'validate percentage', ->
        spec = 
            hscw: [{validator:'percentage'}]

        describe 'validate valid percentage', ->
            it 'should succeed', ->
                for p in [44.99,0,100,-0]
                    result = dbc.validate {hscw: p}, spec
                    expect(result.length).toBe(0)

        describe 'validate invalid percentage', ->
            it 'should fail', ->
                for p in [-10,'cat',100.1]
                    result = dbc.validate {hscw: p}, spec
                    expect(result.length).toBe(1)

    describe 'validate NaN as a number', ->
        o = { age: NaN }
        spec = 
            age: [{validator:'type', args: ['number']}]

        it 'should fail', ->
            result = dbc.validate o, spec
            expect(result.length).toBe(1)

    describe 'validate undefined', ->
        o = undefined
        spec =
            a: [{validator: 'required', args: ['failed truthyness']}, {validator: 'type', args: ['number']}]
            b: [{validator: 'type', args: ['string','failed string']}]
            c: [{validator: 'isFunction', args: [{message: 'c must be a function', field: 'c'}]}]
            d: [{validator: 'type', args: ['object']}]
            e: [{validator: 'required'}]

        it 'should throw', ->
            expect(-> dbc.validate o, spec).toThrow()

    describe 'validate children', ->
        Cut = dbc.makeConstructor
            Id: [{ validator: 'type', args: ['number'] }]
            Name: [{ validator: 'type', args: ['string'] }]
        ThingWithACut = dbc.makeConstructor
            ACut: [{validator: 'dbcType', args: [Cut]}]

        describe 'valid child', ->
            o = {ACut: { Id: 1, Name: 'd-rump' }}

            it 'should validate successfully', ->
                result = dbc.validate o, ThingWithACut.__spec
                expect(result.length).toBe(0)

        describe 'invalid child', ->
            o = {ACut: { Id: 1 }}

            it 'should fail validation', ->
                result = dbc.validate o, ThingWithACut.__spec
                expect(result.length).toBe(1)

    describe 'validate child collections', ->
        Cut = dbc.makeConstructor
            Id: [{ validator: 'type', args: ['number'] }]
            Name: [{ validator: 'type', args: ['string'] }]
        ThingWithACut = dbc.makeConstructor
            ACuts: [{validator: 'dbcTypes', args: [Cut]}]

        describe 'valid children', ->
            o = {ACuts: [{ Id: 1, Name: 'd-rump' },{ Id: 77, Name: '' }]}

            it 'should validate successfully', ->
                result = dbc.validate o, ThingWithACut.__spec
                expect(result.length).toBe(0)

        describe 'invalid child', ->
            o = {ACuts: [{Id:2, Name:'Foo'},{ Id: 1 }]}

            it 'should fail validation', ->
                result = dbc.validate o, ThingWithACut.__spec
                expect(result.length).toBe(1)

    describe 'validate child collection', ->

    describe 'validate', ->

        describe 'simple object types not matching spec', ->
            o =
                a: false
                b: ['strings']
                c: /^abc$/
                d: -2
            spec =
                a: [{validator: 'required', args: ['failed truthyness']}, {validator: 'type', args: ['number']}]
                b: [{validator: 'type', args: ['string','failed string']}]
                c: [{validator: 'isFunction', args: [{message: 'c must be a function', field: 'c'}]}]
                d: [{validator: 'type', args: ['object']}]
                e: [{validator: 'required'}]

            it 'should fail', ->
                result = dbc.validate o, spec
                expect(result.length).toBe(5)


    describe 'check', ->

        describe 'with message arg', ->
            o =
                a: 'foo'
            spec =
                a: [{validator: 'required'},{validator: 'type', args: ['string']}]
                b: [{validator: 'required'}]

            it 'should throw with message', ->
                expect(-> dbc.check o, spec, 'this is a message').toThrow(new Error('this is a message: expected a defined value'))

        describe 'simple object types matching spec', ->
            o =
                a: 1
                b: 'foo'
            spec =
                a: [{validator: 'required'}, {validator: 'type', args: ['number']}]
                b: [{validator: 'type', args: ['string']}]

            it 'should pass', ->
                dbc.check o, spec

        describe 'simple object with extra property', ->
            o =
                a: 1
                b: 'foo'
                c: 'extra'
            spec =
                a: [{validator: 'required'}, {validator: 'type', args: ['number']}]
                b: [{validator: 'type', args: ['string']}]

            it 'should pass', ->
                dbc.check o, spec

        describe 'simple object types not matching spec', ->
            o =
                a: false
                b: 'foo'
            spec =
                a: [{validator: 'required', args: ['failed truthyness']}, {validator: 'type', args: ['number', 'failed number']}]
                b: [{validator: 'type', args: ['string','failed string']}]

            it 'should fail', ->
                expect(-> dbc.check o, spec).toThrow()

        describe 'simple object types with not allowed null', ->
            o =
                a: null
                b: 'foo'
            spec =
                a: [{validator: 'required'}, {validator: 'type', args: ['number']}]
                b: [{validator: 'type', args: ['string']}]

            it 'should fail', ->
                expect(-> dbc.check o, spec).toThrow()

        describe 'simple object types with not allowed undefined', ->
            o =
                b: 'foo'
            spec =
                a: [{validator: 'required', args: ['number']}, {validator: 'type', args: ['number']}]
                b: [{validator: 'type', args: ['string']}]

            it 'should fail', ->
                expect(-> dbc.check o, spec).toThrow()

        describe 'simple object types with allowed undefined', ->
            o =
                a: 987979
            spec =
                a: [{validator: 'required', args: ['number']}, {validator: 'type', args: ['number']}]
                b: [{validator: 'type', args: ['string?']}]

            it 'should pass', ->
                dbc.check o, spec

        describe 'simple object types with allowed null', ->
            o =
                a: -1
                b: null
            spec =
                a: [{validator: 'required', args: ['number']}, {validator: 'type', args: ['number']}]
                b: [{validator: 'type', args: ['string?']}]

            it 'should pass', ->
                dbc.check o, spec

        describe 'object with function', ->
            o =
                a: -1
                f: (v) -> v * v
            spec =
                a: [{validator: 'required', args: ['number']}, {validator: 'type', args: ['number']}]
                f: [{validator: 'isFunction'}]

            it 'should pass', ->
                dbc.check o, spec

        describe 'object without a function', ->
            o =
                a: -1
                f: 5
            spec =
                a: [{validator: 'required', args: ['number']}, {validator: 'type', args: ['number']}]
                f: [{validator: 'isFunction'}]

            it 'should fail', ->
                expect(-> dbc.check o, spec).toThrow()

    describe 'assert is array', ->

        describe 'array', ->
            it 'should pass', ->
                dbc.isArray([1,2,3])

            describe 'empty array', ->
                it 'should pass', ->
                    dbc.isArray([])

        describe 'array like', ->
            it 'should throw', ->
                expect(-> dbc.isArray arguments).toThrow()

        describe 'not an array', ->
            it 'should throw', ->
                expect(-> dbc.isArray 'cat').toThrow()

    describe 'assert isNonEmptyCollection', ->
        describe 'array', ->
            describe 'empty', ->
                it 'should throw', ->
                    expect(-> dbc.isNonEmptyCollection []).toThrow()
            describe 'non empty', ->
                it 'should pass', ->
                    dbc.isNonEmptyCollection [1,2,3]

        describe 'object', ->
            it 'should throw', ->
                expect(-> dbc.isNonEmptyCollection {a:1}).toThrow()

        describe 'string', ->
            it 'should pass', ->
                dbc.isNonEmptyCollection 'foo'

        describe 'custom collection', ->
            it 'should pass', ->
                dbc.isNonEmptyCollection {length:1}

    describe 'assert isEnumerable', ->
        describe 'array', ->
            it 'should pass', ->
                dbc.isEnumerable([])

        describe 'object', ->
            it 'should throw', ->
                expect(-> dbc.isEnumerable({a:1})).toThrow()

        describe 'custom enumerable', ->

            describe 'with foreach function', ->
                it 'should pass', ->
                    dbc.isEnumerable {forEach: ->}

            describe 'without foreach function', ->
                it 'should throw', ->
                    expect(-> dbc.isEnumerable {forEach: 1}).toThrow()

    describe 'assert type', ->

        describe 'for matching array', ->
            it 'should pass', ->
                dbc.type [1,2,3], 'array'

        describe 'for matching string', ->
            it 'should pass', ->
                dbc.type 'hello world', 'string'

        describe 'for not matching string', ->
            it 'should fail', ->
                expect(-> dbc.type 8, 'string').toThrow()

    describe 'required', ->

        describe 'for 0', ->
            it 'should pass', ->
                dbc.required 0

        describe 'for object', ->
            it 'should pass', ->
                dbc.required({a: 1})

        describe 'for empty object', ->
            it 'should pass', ->
                dbc.required {}

        describe 'for null', ->
            it 'should fail', ->
                expect(-> dbc.required null).toThrow()

        describe 'for undefined', ->
            it 'should fail', ->
                expect(-> dbc.required undefined).toThrow()

    describe 'custom', ->
        describe 'greater than zero', ->
            greater_than_zero = (v) -> v > 0

            describe '7', ->
                it 'should pass', ->
                    dbc.custom 7, greater_than_zero

            describe '0', ->
                it 'should throw', ->
                    expect(-> dbc.custom 0, greater_than_zero).toThrow()

            describe '-4', ->
                it 'should throw', ->
                    expect(-> dbc.custom -4, greater_than_zero).toThrow()

            describe 'with message', ->
                message = "Must be greater than zero"

                describe '0', ->
                    it 'should throw', ->
                        expect(-> dbc.custom 0, greater_than_zero, message).toThrow(new Error(message))


