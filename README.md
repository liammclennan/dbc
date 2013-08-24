`dbc` is a small library for design-by-contract defensive coding in javascript. 

It focuses especially on type assertions in an attempt to provide a small compensation for JavaScript's unfortunate dynamicness. Some of the ideas were borrowed from ristretto-js.

The core features are:

 * validate values against a specification
 * generate type constructors from a specification
 * runtime validation of function arguments and return value (via the `wrap` combinator)

[API Documentation](https://rawgithub.com/liammclennan/dbc/master/docs/dbc.html)

Install
---

    npm install dbc

Features
--------

Check a value:

```javascript
    dbc.type(1, 'number', 'optional error message');
    dbc.isFunction(function () {}, 'optional error message');
    dbc.functionArity(function () {}, 0, 'optional error message');
    // etc
```

Check an object:

```javascript
    dbc.check({
        a: 1,
        b: "cat in the hat",
        c: function (f, s) { return f + s; }
    }, {
        a: [
            {validator: 'required', args: ['optional error message']}, 
            {validator: 'type', args: ['number']}, 
            {validator: 'custom', args: [ function (v) { 
                // custom validator function should return a boolean
                return v > 0; 
            }]}
        ],
        b: [{validator: 'type', args: ['string']}],
        c: [{validator: 'isFunction'}, {validator: 'functionArity', args: [2, {message: 'This is a more advanced error object', field: 'c'}]}]
    });
```

Validate an object (same as check except that it returns an array of errors instead of throwing an exception at the first error):

```javascript
    dbc.validate({
        a: 1,
        b: "cat in the hat",
        c: function (f, s) { return f + s; }
    }, {
        a: [
            {validator: 'required', args: ['optional error message']}, 
            {validator: 'type', args: ['number']}, 
            {validator: 'custom', args: [ function (v) { 
                // custom validator function should return a boolean
                return v > 0; 
            }]}
        ],
        b: [{validator: 'type', args: ['string']}],
        c: [{validator: 'isFunction'}, {validator: 'functionArity', args: [2, {message: 'This is a more advanced error object', field: 'c'}]}]
    });
```

Test
----

    npm install -g jasmine-node
    jasmine-node --coffee spec/
