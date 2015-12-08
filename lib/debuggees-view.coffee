{$$, SelectListView} = require 'atom-space-pen-views'

module.exports =
class DebuggeesView extends SelectListView
  callback: null

  initialize: ->
    super
    @addClass('symbols-view')
    @setLoading('Fetching debug targets...')
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @focusFilterEditor()

  viewForItem: ({agentVersion, description, id, labels, project, uniquifier}) ->
    return $$ ->
      @li class: 'two-lines', =>
        @div "#{description}", class: 'primary-line'
        @div "#{agentVersion}", class: 'secondary-line'

  getEmptyMessage: (itemCount) ->
    if itemCount is 0
      'No active debuggees found'
    else
      super

  confirmed: (debuggee) ->
    console.log debuggee, 'was selected'
    @callback debuggee.id
    @cancel()

  destroy: ->
    @cancel()
    @panel.destroy()

  cancelled: ->
    @panel?.hide()
