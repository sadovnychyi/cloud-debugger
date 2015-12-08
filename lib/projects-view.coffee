{$$, SelectListView} = require 'atom-space-pen-views'

module.exports =
class ProjectsView extends SelectListView
  callback: null

  initialize: ->
    super
    @addClass('symbols-view')
    @setLoading('Fetching project list...')
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @focusFilterEditor()

  viewForItem: ({name, projectId, projectNumber}) ->
    return $$ ->
      @li class: 'two-lines', =>
        @div "#{name} (#{projectId})", class: 'primary-line'
        @div "projectNumber: #{projectNumber}", class: 'secondary-line'

  getEmptyMessage: (itemCount) ->
    if itemCount is 0
      'No projects found'
    else
      super

  confirmed: (project) ->
    console.log project, 'was selected'
    @callback project
    @cancel()

  destroy: ->
    @cancel()
    @panel.destroy()

  cancelled: ->
    @panel?.hide()
