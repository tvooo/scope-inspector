# to do: erkennt erste anonyme func noch nicht
# var server = http.createServer( function( req, res ) {
#  parseMarkdown( function( err, data ) {
#    compileHtml( data, function( err, data ) {
#      res.end( data );
#    });
#  } );
# });

esprima = require 'esprima'
_ = require 'lodash'

extend = (obj, mixin) ->
  obj[name] = method for name, method of mixin
  obj

include = (klass, mixin) ->
  extend klass.prototype, mixin

Identifier =
  getShadowedIdentifier: ->
    scope = @parentScope.parentScope

    while scope?
      id = scope.getIdentifier(@name)
      if id isnt null
        id.shadowedBy.push @
        return id
      else
        scope = scope.parentScope
    null

class Variable
  constructor: (@node, @parentScope) ->
    @type = @node.type
    @name = @node.id.name
    @shadowedBy = []

class Parameter
  constructor: (@node, @parentScope) ->
    @name = @node.name
    @shadowedBy = []

class Scope
  constructor: (@node, @parentScope = null) ->
    @parentScope ?= null
    body = if @parentScope? then @node.body.body else @node.body
    @loc = @node.loc

    @children = []

    @variables = []
    @functions = []

    # Getting all variables

    varDeclarations = (value for value in body when value.type == 'VariableDeclaration')
    for declaration in varDeclarations
      for declarator in declaration.declarations
        variable = new Variable(declarator, @)

        if variable.node.init?.type == "FunctionExpression"
          @functions.push new Funktion(variable.node.init, @, variable)
        else
          @variables.push variable

    # Getting all functions
    @functions.push(new Funktion(value, @)) for value in body when value.type == 'FunctionDeclaration'

    # Getting all function expressions
    expressionStatements = (statement for statement in body when statement.type == 'ExpressionStatement')
    for statement in expressionStatements
      if statement.expression.type == 'CallExpression'
        call = statement.expression
        for argument in call.arguments when argument.type == 'FunctionExpression'
          @functions.push new Funktion(argument, @)

    @name = "GLOBAL" if not @parentScope?

    # Registering children
    @children.push @variables
    @children.push @functions

  # Returns a child identifier from this scope
  getIdentifier: (name) ->
    for child in @children
      id = _.find(child, { 'name': name })
      #if id.type == "FunctionExpression" and id.isAnonymous
      if id and not id.isAnonymous
        return id
    return null

  checkForShadowing: ->
    for child in @children
      for id in child
        id.shadows = id.getShadowedIdentifier()

  constructShadowingInformation: ->
    for id in @functions
      id.constructShadowingInformation()
    @checkForShadowing()

class Funktion extends Scope
  constructor: (@node, @parentScope, @identifier) ->
    @type = @node.type
    @shadowedBy = []
    @isAnonymous = false
    if @node.id?
      @name = @node.id.name
    else if @identifier?
      @name = @identifier.name
    else
      @isAnonymous = true
      @name = "(anonymous function)"

    super(@node, @parentScope)
    @params = (new Parameter(param, @) for param in @node.params)

    @children.push @params

include Variable, Identifier
include Parameter, Identifier
include Funktion, Identifier

getNestedScopes = (scope) ->
  [scope].concat( if scope.parentScope? then getNestedScopes(scope.parentScope) else [] )

module.exports =
  getScopeTree: (text) ->
    syntax = esprima.parse text, range: true, loc: true

    global = new Scope syntax
    global.constructShadowingInformation()
    return global
  getNestedScopes: getNestedScopes
