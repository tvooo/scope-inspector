esprima = require 'esprima'
_ = require 'lodash'

scope = (object) ->
  varDeclarations = (value for own key, value of object when value.type == 'VariableDeclaration')
  vars = _.flatten(for decl in varDeclarations
    d for d in decl.declarations
  )

  funs = (value for own key, value of object when value.type == 'FunctionDeclaration')
  for fun in funs
    fun.scope = scope(fun.body.body)

  #console.log declarations
  #console.log varDecls
  return {
    vars: vars
    funs: funs
  }


module.exports =
  getScopes: (text) ->
    syntax = esprima.parse text

    global = scope syntax.body
    console.log (vars.id.name for vars in global.vars).join(', ')
    console.log (vars.id.name for vars in global.funs[2].scope.vars).join(', ')
    console.log global.funs[2].scope
    "ende"
