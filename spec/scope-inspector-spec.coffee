{WorkspaceView} = require 'atom'
ScopeInspector = require '../lib/scope-inspector'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "ScopeInspector", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('scope-inspector')

  describe "when the scope-inspector:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.scope-inspector')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.workspaceView.trigger 'scope-inspector:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.scope-inspector')).toExist()
        atom.workspaceView.trigger 'scope-inspector:toggle'
        expect(atom.workspaceView.find('.scope-inspector')).not.toExist()
