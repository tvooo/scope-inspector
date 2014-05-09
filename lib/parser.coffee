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

    @variables = []
    @functions = []

    varDeclarations = (value for value in body when value.type == 'VariableDeclaration')
    for declaration in varDeclarations
      for declarator in declaration.declarations
        variable = new Variable(declarator)

        if variable.node.init?.type == "FunctionExpression"
          @functions.push new Function(variable.node.init, @, variable)
        else
          @variables.push variable

    @functions.push(new Function(value, @)) for value in body when value.type == 'FunctionDeclaration'

    expressionStatements = (statement for statement in body when statement.type == 'ExpressionStatement')
    for statement in expressionStatements
      if statement.expression.type == 'CallExpression'
        call = statement.expression
        for argument in call.arguments when argument.type == 'FunctionExpression'
          @functions.push new Function(argument, @)


    @name = "GLOBAL" if not @parentScope?

class Function extends Scope
  constructor: (@node, @parentScope, @identifier) ->
    super(@node, @parentScope)
    @type = @node.type
    if @node.id?
      @name = @node.id.name
    else if @identifier
      @name = @identifier.name
    else
      @name = "(anonymous function)"
    @params = (new Parameter(param) for param in @node.params)

getNestedScopes = (scope) ->
  [scope].concat( if scope.parentScope? then getNestedScopes(scope.parentScope) else [] )

module.exports =
  getScopeTree: (text) ->
    syntax = esprima.parse text, range: true, loc: true

    global = new Scope syntax
  getNestedScopes: getNestedScopes
