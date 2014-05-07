// Generated by CoffeeScript 1.7.1
(function() {
  var esprima, scope, _,
    __hasProp = {}.hasOwnProperty;

  esprima = require('esprima');

  _ = require('lodash');

  scope = function(object) {
    var d, decl, fun, funs, key, value, varDeclarations, vars, _i, _len;
    varDeclarations = (function() {
      var _results;
      _results = [];
      for (key in object) {
        if (!__hasProp.call(object, key)) continue;
        value = object[key];
        if (value.type === 'VariableDeclaration') {
          _results.push(value);
        }
      }
      return _results;
    })();
    vars = _.flatten((function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = varDeclarations.length; _i < _len; _i++) {
        decl = varDeclarations[_i];
        _results.push((function() {
          var _j, _len1, _ref, _results1;
          _ref = decl.declarations;
          _results1 = [];
          for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
            d = _ref[_j];
            _results1.push(d);
          }
          return _results1;
        })());
      }
      return _results;
    })());
    funs = (function() {
      var _results;
      _results = [];
      for (key in object) {
        if (!__hasProp.call(object, key)) continue;
        value = object[key];
        if (value.type === 'FunctionDeclaration') {
          _results.push(value);
        }
      }
      return _results;
    })();
    for (_i = 0, _len = funs.length; _i < _len; _i++) {
      fun = funs[_i];
      fun.scope = scope(fun.body.body);
    }
    return {
      vars: vars,
      funs: funs
    };
  };

  module.exports = {
    getScopes: function(text) {
      var global, syntax, vars;
      syntax = esprima.parse(text);
      global = scope(syntax.body);
      console.log(((function() {
        var _i, _len, _ref, _results;
        _ref = global.vars;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          vars = _ref[_i];
          _results.push(vars.id.name);
        }
        return _results;
      })()).join(', '));
      console.log(((function() {
        var _i, _len, _ref, _results;
        _ref = global.funs[2].scope.vars;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          vars = _ref[_i];
          _results.push(vars.id.name);
        }
        return _results;
      })()).join(', '));
      console.log(global.funs[2].scope);
      return "ende";
    }
  };

}).call(this);