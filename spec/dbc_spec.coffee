## <reference path="../../../EnergyMarkets.Web/Scripts/underscore.js" />
## <reference path="../../../EnergyMarkets.Web/Scripts/src/modules.js" />
## <reference path="../../../EnergyMarkets.Web/Scripts/src/dbc.js" />



describe 'dbc', ->
	dbc = require '../dbc'

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

		describe 'simple object types matching spec', ->
			o = 
				a: 1
				b: 'foo'
			spec = 
				a: [{validator: 'required', args: ['number']}, {validator: 'type', args: ['number']}]
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
				b: [{validator: 'type', args: ['string']}]

			it 'should fail', ->
				dbc.check o, spec
				
		describe 'simple object types with allowed null', ->
			o = 
				a: -1
				b: null
			spec = 
				a: [{validator: 'required', args: ['number']}, {validator: 'type', args: ['number']}]
				b: [{validator: 'type', args: ['string']}]

			it 'should fail', ->
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
						
				