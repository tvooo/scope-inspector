esprima = require 'esprima'
_ = require 'lodash'

class Variable
  constructor: (@node) ->
    @type = @node.type
    @name = @node.id.name

class Parameter
  constructor: (@node) ->
    @name = @node.name

class Scope
  constructor: (@node, @parentScope) ->
    @parentScope ?= null
    body = if @parentScope? then @node.body.body else @node.body
    @loc = @node.loc

    varDeclarations = (value for value in body when value.type == 'VariableDeclaration')

    @variables = _.flatten(for decl in varDeclarations
      new Variable(d) for d in decl.declarations
    )

    @functions = (new Function(value, @) for value in body when value.type == 'FunctionDeclaration')

    @name = "GLOBAL" if not @parentScope?

class Function extends Scope
  constructor: (@node, @parentScope) ->
    super(@node, @parentScope)
    @type = @node.type
    @name = @node.id.name
    @params = (new Parameter(param) for param in @node.params)
    console.log @params


getNestedScopes = (scope) ->
  [scope].concat( if scope.parentScope? then getNestedScopes(scope.parentScope) else [] )

module.exports =
  getScopeTree: (text) ->
    syntax = esprima.parse text, range: true, loc: true

    global = new Scope syntax
  getNestedScopes: getNestedScopes
