esprima = require 'esprima'
_ = require 'lodash'

class Variable
  constructor: (@node) ->
    @type = @node.type
    @name = @node.id.name

class Scope
  constructor: (object, @parentScope) ->
    @parentScope ?= null

    varDeclarations = (value for own key, value of object when value.type == 'VariableDeclaration')

    @variables = _.flatten(for decl in varDeclarations
      new Variable(d) for d in decl.declarations
    )

    @functions = (new Function(value, @) for own key, value of object when value.type == 'FunctionDeclaration')

    @name = "GLOBAL" if not @parentScope?

class Function extends Scope
  constructor: (@node, @parentScope) ->
    super(@node.body.body, @parentScope)
    @type = @node.type
    @name = @node.id.name

getNestedScopes = (scope) ->
  [scope].concat( if scope.parentScope? then getNestedScopes(scope.parentScope) else [] )

module.exports =
  getScopeTree: (text) ->
    syntax = esprima.parse text

    global = new Scope syntax.body
  getNestedScopes: getNestedScopes
