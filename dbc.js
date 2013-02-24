(function() {

  module.exports = {
    assert: function(condition, message) {
      if (!condition) {
        throw new Error(message);
      }
    },
    assert_is_function: function(f, message) {
      if (!((f != null) && typeof f === 'function')) {
        throw new Error(message != null ? message : message = 'expected a function');
      }
    },
    assert_is_instance: function(o, type, message) {
      if (!(o instanceof type)) {
        throw new Error(message != null ? message : message = "expected " + o + " to be an instance of " + type.name);
      }
    }
  };

}).call(this);
