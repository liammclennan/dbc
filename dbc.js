(function() {

  module.exports = {
    assert: function(condition, message) {
      if (!condition) {
        throw new Error(message);
      }
    },
    assertIsFunction: function(f, message) {
      if (!((f != null) && typeof f === 'function')) {
        throw new Error(message != null ? message : message = 'expected a function');
      }
    },
    assertIsInstance: function(o, type, message) {
      if (!(o instanceof type)) {
        throw new Error(message != null ? message : message = "expected " + o + " to be an instance of " + type.name);
      }
    },
    assertPropertyTypes: function(o, definition) {
      for (var key in definition) {
        if (typeof o[key] !== definition[key]) {
          throw new Error('expected property ' + key + ' of type ' + definition[key]);
        }
      }
    },
    assertFunctionArity: function(f, arity, message) {
      this.assertIsFunction(f, 'cannot check arity of an object that is not a function');
      if (f.length !== arity) {
        throw new Error(message || 'Function arity is ' + f.length + '. Expected ' + arity);
      }
    }
  };

}).call(this);
