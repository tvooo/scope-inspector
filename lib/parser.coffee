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

class Variable
  constructor: (@node, @parentScope) ->
    @type = @node.type
    @name = @node.id.name
    @shadowedBy = []

  getShadowedIdentifier: ->
    scope = @parentScope.parentScope
    while scope isnt null
      id = scope.getIdentifier(@name)
      if id isnt null
        id.shadowedBy.push @
        return id
      else
        scope = scope.parentScope
    null


class Parameter
  constructor: (@node, @parentScope) ->
    @name = @node.name
    @shadowedBy = []

  getShadowedIdentifier: ->
    scope = @parentScope.parentScope?
    return null unless scope.parentScope?.parentScope? isnt null
    while scope isnt null
      id = scope.getIdentifier(@name)
      #console.log @name, id
      if id then return id else scope = scope.parentScope
    null

class Scope
  constructor: (@node, @parentScope) ->
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
          @functions.push new Function(variable.node.init, @, variable)
        else
          @variables.push variable

    # Getting all functions
    @functions.push(new Function(value, @)) for value in body when value.type == 'FunctionDeclaration'

    # Getting all function expressions
    expressionStatements = (statement for statement in body when statement.type == 'ExpressionStatement')
    for statement in expressionStatements
      if statement.expression.type == 'CallExpression'
        call = statement.expression
        for argument in call.arguments when argument.type == 'FunctionExpression'
          @functions.push new Function(argument, @)

    @name = "GLOBAL" if not @parentScope?

    # Registering children
    @children.push @variables
    #@children.push @functions

    @checkForShadowing() if @.constructor == Scope

  getIdentifier: (name) ->
    _.find(@variables, { 'name': name }) ||
      _.find(@functions, { 'name': name }) ||
      _.find(@params, { 'name': name }) ||
      null

  checkForShadowing: ->
    for child in @children
      for id in child
        id.shadows = id.getShadowedIdentifier()

class Function extends Scope
  constructor: (@node, @parentScope, @identifier) ->
    super(@node, @parentScope)
    @type = @node.type
    @shadowedBy = []
    if @node.id?
      @name = @node.id.name
    else if @identifier
      @name = @identifier.name
    else
      @name = "(anonymous function)"
    @params = (new Parameter(param, @) for param in @node.params)

    #@children.push @params

    @checkForShadowing() if @.constructor == Function

  getShadowedIdentifier: ->
    scope = @parentScope.parentScope?
    return null unless scope.parentScope?.parentScope? isnt null
    while scope isnt null
      id = scope.getIdentifier(@name)
      #console.log @name, id
      if id then return id else scope = scope.parentScope
    null

getNestedScopes = (scope) ->
  [scope].concat( if scope.parentScope? then getNestedScopes(scope.parentScope) else [] )

module.exports =
  getScopeTree: (text) ->
    syntax = esprima.parse text, range: true, loc: true

    global = new Scope syntax
  getNestedScopes: getNestedScopes
