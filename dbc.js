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

        // will throw on first error
        check: function(o, spec, message) {
            message = message || ''
            mode = 'check';
            try {
                applyValidators.call(this, o, spec);    
            } catch (e) {
                throw new Error(message ? message + ': ' + e.message : e.message);
            }            
        },

        // wrap
        // ----
        // Wrap returns a wrapped function that applies 'specs' validators to the
        // functions arguments and 'returnSpec' validators to the return value.
        // ie 
        // 
        //      dbc.wrap(function add(f,s) { return f + s;}, {
        //          0: [{validator:'type', args:['number']}],
        //          1:[{validator:'type', args:['number']}]
        //      }, [{validator: 'type', args:['number']}]);
        wrap: function(original, specs, returnSpec) {
            return function () {
                var r;
                checkArgs(arguments);
                r = original.apply(this,arguments);
                checkReturn();
                return r;

                function checkArgs(args) {
                    _.each(_.keys(specs || {}), function (k,index) {
                        var o={},s={};
                        o[k] = args[index];
                        s[k] = specs[k];
                        dbc.check(o,s);
                    });
                }
                function checkReturn() {
                    if (returnSpec) {
                        dbc.check({ret: r}, {ret: returnSpec});
                    }
                }
            };       
        },

        // generate a constructor from a spec. The constructor
        // validates that created objects meet the spec.
        // ie   var Person = dbc.MakeConstructor({
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
                dbc.check(c, c.__spec);
            };
            f.prototype.__spec = spec;
            return f;
        },


        // will return an array of messages
        validate: function (o, spec) {
            mode = 'validate';
            applyValidators.call(this, o, spec);
            return messages;
        },
        custom: function(v, test, message) {
            if (!isExisting(v)) return;
            
            if (!test(v)) {
                storeMessage(message || 'failed custom function condition for value ' + v);
            }
        },
        assert: function(condition, message) {
            if (!condition) {
                storeMessage(message);
            }
        },
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
                storeMessage('Expected type of ' + type + ' but was null or undefined');
            }
            if ((typeof v) != type) {
                storeMessage(message);
            }
        },
        required: function(v, message) {
            if (!isExisting(v)) {
                storeMessage(message || 'expected a defined value');
            }  
        },
        isArray: function (v, message) {
            if (isExisting(v) && !_.isArray(v)) {
                storeMessage(message || 'expected an array')
            }
        },
        isEnumerable: function (v, message) {
            if (isExisting(v) && typeof v.forEach !== 'function') {
                storeMessage(message || 'expected an object with a forEach function');
            }
        },
        isNonEmptyCollection: function (v, message) {
            if (!isExisting(v)) return;
            
            if (!(typeof v.length === 'number' && v.length > 0)) {
                throw new Error(message || 'expected collection with length > 0');
            }
        },
        isFunction: function(f, message) {
            if (isExisting(f) && typeof f != 'function') {
                storeMessage(message || 'expected a function');
            }
        },
        isObject: function(o, message) {
            if (isExisting(o) && (typeof o) != 'object') {
                storeMessage(message || 'argument is not an object');
            }
        },
        isInstance: function(o, type, message) {
            if (!isExisting(o) && !(o instanceof type)) {
                storeMessage(message || "expected " + o + " to be an instance of " + type.name);
            }
        },
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
        var specKeys = _.keys(spec),
            dbc = this;

        specKeys.forEach(function (key) {
            var validators = spec[key];
            
            validators.forEach(function(validator) {
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
