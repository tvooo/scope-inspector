# to do: erkennt erste anonyme func noch nicht
# var server = http.createServer( function( req, res ) {
#  parseMarkdown( function( err, data ) {
#    compileHtml( data, function( err, data ) {
#      res.end( data );
#    });
#  } );
# });
#
# Auch das nicht:
# ret[l] = _.sortBy(ret[l], function (el) {
#  return el.character;
#});

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
    @hoisted = false

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

    # Going through all the statements
    hoisting = false

    for statement in body

      # All the variables

      if statement.type == 'VariableDeclaration'
        for declarator in statement.declarations
          variable = new Variable(declarator, @)
          variable.hoisted = hoisting
          #console.log "#{variable.name} will be hoisted :)" if hoisting
          if variable.node.init?.type == "FunctionExpression"
            @functions.push new Funktion(variable.node.init, @, variable)
          else
            @variables.push variable
      else
        hoisting = true

      # All the function declarations

      if statement.type == 'FunctionDeclaration'
        @functions.push new Funktion(statement, @)

      # All the function expressions

      else if statement.type == 'ExpressionStatement'
        if statement.expression.type == 'CallExpression'
          call = statement.expression
          for argument in call.arguments when argument.type == 'FunctionExpression'
            @functions.push new Funktion(argument, @)

    #varDeclarations = (value for value in body when value.type == 'VariableDeclaration')

    # Getting all functions
    #@functions.push(new Funktion(value, @)) for value in body when value.type == 'FunctionDeclaration'

    # Getting all function expressions
    #expressionStatements = (statement for statement in body when statement.type == 'ExpressionStatement')
    #for statement in expressionStatements


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

  getHoistedIdentifiers: ->
    (id for id in @variables when id.hoisted)

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
