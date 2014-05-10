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
    @hoisting = false
    @hoistingPosition = null

    for statement, index in body
      # Set hoistingPosition for first statement
      @hoistingPosition = statement.loc if 0 == index
      @parseNode statement

    @name = "GLOBAL" if not @parentScope?

    # Registering children
    @children.push @variables
    @children.push @functions

  parseNode: (node, identifier) ->

    return unless node?

    if node.type isnt "VariableDeclaration"
      @hoisting = true

    switch node.type

      when "ExpressionStatement"
        @parseNode(node.expression)

      # *Expressions
      when "FunctionExpression"
        @functions.push new Funktion(node, @, identifier)

      when "CallExpression"
        @parseNode node.callee
        @parseNode(argument) for argument in node.arguments

      when "MemberExpression"
        @parseNode node.object
        @parseNode node.property

      when "AssignmentExpression"
        @parseNode node.left
        @parseNode node.right

      # *Declarations
      when "VariableDeclaration"
        for declarator in node.declarations
          variable = new Variable(declarator, @)
          variable.hoisted = @hoisting
          if variable.node.init
            @parseNode(variable.node.init, identifier)
          @variables.push variable

      when "FunctionDeclaration"
        @functions.push new Funktion(node, @)

      when "IfStatement"
        @parseNode node.test
        @parseNode node.consequent
        @parseNode node.alternate

      when "WhileStatement"
        @parseNode node.test
        @parseNode node.body

      when "ForStatement"
        @parseNode node.init
        @parseNode node.test
        @parseNode node.update
        @parseNode node.body

      when "SwitchStatement"
        @parseNode node.discriminant
        @parseNode(statement) for statement in node.cases

      when "SwitchCase"
        @parseNode node.test
        @parseNode node.consequent

      when "BlockStatement"
        @parseNode(statement) for statement in node.body

      when "Identifier"
        # Do nothing
        return

      when "EmptyStatement"
        # Do nothing
        return

      when "Literal"
        # Do nothing
        return

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

  getAllScopes: ->
    result = [@]
    for scope in @functions
      result = result.concat scope.getAllScopes()

    return result

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
