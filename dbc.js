// dbc
// ===
// `dbc` is a small library for design-by-contract style defensive coding in javascript. 
// 

(function () {
    var mode
        , messages = [];
    var _ = this._ || require('underscore');
        
    dbc = {

        // Public API
        // ==========

        // check
        // ---
        // Check asserts that an object `o` meets a specification `spec`.
        // If `o` does not satisfy `spec` then an exception is thrown. 
        // eg.
        //
        //      dbc.check({
        //          name: 'John',
        //          age: 22
        //      }, {
        //          name: [{validator:'type',args:['string']}],
        //          age: [{validator:'type',args:['number']}],
        //      });
        check: function(o, spec, message) {            
            message = message || '';
            messages = [];
            mode = 'check';
            try {
                applyValidators.call(this, o, spec);    
            } catch (e) {
                throw new Error(message ? message + ': ' + e.message : e.message);
            }            
        },

        // validate
        // -----
        // Validate is the same as check, except that errors are returned
        // as an array of messages instead of throwing an exception.
        validate: function (o, spec) {
            mode = 'validate';
            messages = [];
            applyValidators.call(this, o, spec);
            return messages;
        },

        // wrap
        // ----
        // Wrap returns a wrapped function that applies 'specs' validators to the
        // functions arguments and 'returnSpec' validators to the return value.
        // eg
        // 
        //      var add = dbc.wrap(function (f,s) { 
        //          return f + s;
        //      }, {
        //          // validators for the first arg
        //          0: [{validator:'type', args:['number']}],
        //          // validators for the second arg
        //          1:[{validator:'type', args:['number']}]
        //      },
        //      // validators for the return value 
        //      [{validator: 'type', args:['number']}]);
        wrap: function(original, specs, returnSpec) {
            return function () {
                var r;
                checkArgs(arguments);
                r = original.apply(this,arguments);
                checkReturn();
                return r;

                function checkArgs(args) {
                    _.each(_.keys(specs || {}), function (k,index) {
                        dbc.check(
                            {k: args[index] },
                            { k: specs[k] });
                    });
                }
                function checkReturn() {
                    if (returnSpec) {
                        dbc.check({ret: r}, {ret: returnSpec});
                    }
                }
            };       
        },

        // makeConstructor
        // ----
        // MakeConstructor generates a constructor from a spec. The constructor
        // validates that the created objects meet the spec.
        // ie   
        //
        //      var Person = dbc.MakeConstructor({
        //          name: [{validator:'type',args:'string'}],
        //          age: [{validator:'type',args:'number'}]
        //      });
        //      Person.prototype.canDrive = dbc.wrap(function () { 
        //          return this.age > 16;
        //      }, null, [{validator:'type',args:'number'}]);
        //      var p = new Person('John', 22);
        //      p.canDrive(); // true 
        makeConstructor: function(spec) {
            var f = function (prps) {
                var c = this;
                _.each(_.keys(spec), function (key) {
                    c[key] = prps[key];         
                });
                dbc.check(c, f.__spec);
            };
            f.__spec = spec;
            return f;
        },

        // custom
        // ---
        // The `custom` validator applies a custom predicate.
        // eg
        //
        //      dbc.check({
        //          number: 7
        //      },{
        //          number: [{validator:'custom',args:[function isEven(n) {
        //              return n % 2 === 0;
        //          }]}]
        //      });
        custom: function(v, test, message) {
            if (!isExisting(v)) return;
            
            if (!test(v)) {
                storeMessage(message || 'failed custom function condition for value ' + v);
            }
        },

        // assert
        // ---
        // Assert is for simple boolean assertions. eg
        //
        //      dbc.assert(6 === 9, 'Six should equal nine');
        assert: function(condition, message) {
            if (!condition) {
                storeMessage(message);
            }
        },

        // type
        // ----
        // Type asserts the type of a value using JavaScript's `typeof` operator. 
        // In addition to the JavaScript types (undefined, object, boolean, number, string, function) you can also use `array`. eg
        //
        //      dbc.check({
        //          name:'John'
        //      }, {
        //          name: [{validator:'type',args: ['string']}]
        //      });
        type: function (v, type, message) {
            if (type.charAt(type.length-1) == '?') {
                if (!isExisting(v)) return;
                type = type.substring(0, type.length-1);
            }

            message = message || 'Expected type of ' + type + ' but was ' + typeof v;
            if (type == 'array') {
                if (!_.isArray(v)) {
                    storeMessage(message)
                }
                return;
            }
            if (typeof v == 'undefined' || v == null) {
                storeMessage(message || 'Expected type of ' + type + ' but was null or undefined');
                return;
            }
            if (type == 'number' && isNaN(v)) {
                storeMessage(message || 'Expected type of ' + type + ' but was NaN');
                return;
            }
            if ((typeof v) != type) {
                storeMessage(message);
            }
        },

        // dbcType
        // -------
        // validate an object against a constructor matching those
        // generated by dbc.makeConstructor.
        //
        // Cut = dbc.makeConstructor
        //     Id: [{ validator: 'type', args: ['number'] }]
        //     Name: [{ validator: 'type', args: ['string'] }]
        // ThingWithACut = dbc.makeConstructor
        //     ACut: [{validator: 'dbcType', args: [Cut]}]
        dbcType: function (v, ctor, message) {     
            if (!isExisting(v)) return;              

            applyValidators.call(this, v, ctor.__spec);            
        },

        // dbcTypes
        // --------
        // same as dbcType except it validates an array.
        dbcTypes: function (v, ctor, message) { 
            if (!isExisting(v)) return;  
            if (!_.isArray(v)) {
                storeMessage(message || 'expected a collection');
                return;                
            }
            if (!ctor.__spec) {
                throw new Error('unable to validate without a __spec property');
            }
            _.each(v, function (vc) {
                applyValidators.call(this, vc, ctor.__spec);            
            },this);            
        },

        // oneOf
        // ---
        // asserts that the value is equal to one of the supplied possibilities.
        //
        //      dbc.oneOf(2, [1,2,3]);
        oneOf: function (v, possibilities, message) {
            if (!isExisting(v)) return;

            if (!_.any(possibilities, function (possibility) {
                return possibility === v;
            })) {
                storeMessage(message || 'expected one of the defined possibilities');
            }
        },

        // required
        // ---
        // Required asserts that a value is not null or undefined. This validator does
        // not require any args. eg
        //
        //      dbc.check({
        //          name:'John'
        //      }, {
        //          name: [{validator:'required'}]
        //      });
        required: function(v, message) {
            if (!isExisting(v)) {
                storeMessage(message || 'expected a defined value');
            }  
        },

        // isArray
        // ---
        // IsArray asserts that a value is an array. This validator does
        // not require any args. eg
        //
        //      dbc.check({
        //          colours: ['red','green','blue']
        //      }, {
        //          colours: [{validator:'isArray'}]
        //      });
        isArray: function (v, message) {
            if (isExisting(v) && !_.isArray(v)) {
                storeMessage(message || 'expected an array')
            }
        },

        // isEnumerable
        // ---
        // IsEnumerable asserts that a value has a forEach function. This validator does
        // not require any args. eg
        //
        //      dbc.check({
        //          colours: ['red','green','blue']
        //      }, {
        //          colours: [{validator:'isEnumerable'}]
        //      });
        isEnumerable: function (v, message) {
            if (isExisting(v) && typeof v.forEach !== 'function') {
                storeMessage(message || 'expected an object with a forEach function');
            }
        },

        // isNonEmptyCollection
        // ---
        // isNonEmptyCollection asserts that a value has a length property greater than zero. This validator does
        // not require any args. eg
        //
        //      dbc.check({
        //          divs: $('div')     // assuming jQuery
        //      }, {
        //          divs: [{validator:'isNonEmptyCollection'}]
        //      });
        isNonEmptyCollection: function (v, message) {
            if (!isExisting(v)) return;
            
            if (!(typeof v.length === 'number' && v.length > 0)) {
                storeMessage(message || 'expected collection with length > 0');
            }
        },

        // isJqueryPromise
        // ---
        // asserts that the object is a jquery promise.
        //
        //      dbc.isJqueryPromise(jQuery.Deferred().promise());
        isJqueryPromise: function (v, message) {
            if (!isExisting(v)) return;

            dbc.hasFunctions(v, ['done','fail','always','then'], message || 'expected a jquery promise object');
        },

        // hasFunctions
        // ---
        // asserts that the object has properties of the supplied names that are functions
        //
        //      dbc.hasFunctions({ toString: function () {} }, ['toString']);
        hasFunctions: function (v, functions, message) {
            if (!isExisting(v)) return;

            _.each(functions, function (functionName) {
                dbc.isFunction(v[functionName], message || 'expected an object with a function ' + functionName);
            });
        },

        // isFunction
        // ---
        // isFunction asserts that a value is a function. This validator does
        // not require any args. eg
        //
        //      dbc.check({
        //          square: function (n) { return n * n; } 
        //      }, {
        //          square: [{validator:'isFunction'}]
        //      });
        isFunction: function(f, message) {
            this.type(f, 'function', message || 'expected a function');
        },

        // isObject
        // ---
        // isObject asserts that a value is an object. This validator does
        // not require any args. eg
        //
        //      dbc.check({
        //          thing: {}
        //      }, {
        //          thing: [{validator:'isObject'}]
        //      });
        isObject: function(o, message) {
            this.type(o, 'object', message || 'expected an object');
        },

        // isInstance
        // ---
        // isInstance asserts the constructor of an object. eg
        //
        //      dbc.check({
        //          john: new Person('John')
        //      }, {
        //          john: [{validator:'isInstance',args:[Person]}]
        //      });
        isInstance: function(o, type, message) {
            if (isExisting(o) && !(o instanceof type)) {
                storeMessage(message || "expected " + o + " to be an instance of " + type.name);
            }
        },

        // functionArity
        // ---
        // functionArity asserts the arity of a function. eg
        //
        //      dbc.check({
        //          add: function (f,s) { return f + s; }
        //      }, {
        //          add: [{validator:'functionArity',args:[2]}]
        //      });
        functionArity: function (f, arity, message) {
            if (!isExisting(f)) return;
            this.isFunction(f, 'cannot check arity of an object that is not a function');
            if (f.length !== arity) {
                storeMessage(message || 'Function arity is ' + f.length + '. Expected ' + arity);
            }
        }
    };
    
    function isExisting(v) {
        return typeof v !== "undefined" && v !== null;
    }

    function applyValidators(o, spec) {
        if (!o) {
            throw new Error("unable to validate undefined");
        }
        if (!spec) {
            throw new Error("unable to validate undefined spec");
        }

        var specKeys = _.keys(spec),
            dbc = this;

        specKeys.forEach(function (key) {
            var validators = spec[key];
            
            validators.forEach(function(validator) {
                if (!dbc[validator.validator]) throw new Error("Validator " + validator.validator + " was not found");
                dbc[validator.validator].apply(dbc, [o[key]].concat(validator.args || []))
            });
        });
    }

    function storeMessage(message) {
        if (mode === 'validate') {
            messages.push(message);    
            return;
        }
        throw new Error(message);
    }

    if (typeof define !== "undefined" && define !== null) {
        define('dbc', [], function () {
            return dbc;
        });
    } else if (typeof window !== "undefined" && window !== null) {
        window.dbc = dbc;
    }

    if (typeof module !== "undefined" && module !== null) {
        module.exports = dbc;
    }

})();
