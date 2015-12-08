ProjectsView = require './projects-view'
DebuggeesView = require './debuggees-view'
{CompositeDisposable} = require 'atom'
google = require 'googleapis'

module.exports = CloudDebugger =
  config:
    debuggeeId:
      type: 'string'
      order: 1
      title: 'Current Debuggee ID'
      description: 'Use command palete to select it.'

  cloudDebuggerView: null
  modalPanel: null
  subscriptions: null

  _authScopes: [
    'https://www.googleapis.com/auth/cloud-platform.read-only'
    'https://www.googleapis.com/auth/cloud_debugger'
  ]

  selectProject: ->
    if @projectsView
      @projectsView.destroy()
    @projectsView = new ProjectsView()
    google.auth.getApplicationDefault (err, authClient) =>
      if err
        @projectsView.destroy()
        throw err
      if authClient.createScopedRequired && authClient.createScopedRequired()
        authClient = authClient.createScoped @_authScopes

      service = google.cloudresourcemanager('v1beta1')
      console.log 'service', service
      service.projects.list
        auth: authClient
        , (err, response) =>
          console.log 'projects', err, response
          if err
            @projectsView.destroy()
            throw err
          @projectsView.callback = @selectDebuggees
          @projectsView.setItems(response.projects)

  selectDebuggees: ({name, projectId, projectNumber}) ->
    console.log 'selectDebuggees', projectNumber
    if @debuggeesView
      @debuggeesView.destroy()
    @debuggeesView = new DebuggeesView()
    google.auth.getApplicationDefault (err, authClient) =>
      if err
        @debuggeesView.destroy()
        throw err
      if authClient.createScopedRequired && authClient.createScopedRequired()
        authClient = authClient.createScoped @_authScopes

      service = google.clouddebugger('v2')
      console.log 'service', service
      service.debugger.debuggees.list
        auth: authClient
        includeInactive: false
        project: projectNumber
        , (err, response) =>
          console.log 'debuggees', err, response
          if err
            @debuggeesView.destroy()
            throw err
          @debuggeesView.callback = (id) ->
            atom.config.set('cloud-debugger.debuggeeId', id)
            atom.notifications.addSuccess(
              '''Successfully set debug target to #{id}.
              Now you can set a breakpoint.
              ''')
          @debuggeesView.setItems(response.debuggees)

  setBreakpoint: ->
    editor = atom.workspace.getActiveTextEditor()
    [_, path] = atom.project.relativizePath(editor.buffer.file.path)
    line = editor.getCursorBufferPosition().row
    console.log "#{path}:#{line}"
    path = 'src/contract.py'
    line = 255
    if not atom.config.get('cloud-debugger.debuggeeId')
      atom.notifications.addWarning('You must select a project first')
      return

    google.auth.getApplicationDefault (err, authClient) =>
      if err
        throw err
      if authClient.createScopedRequired && authClient.createScopedRequired()
        authClient = authClient.createScoped @_authScopes
      service = google.clouddebugger('v2')
      console.log 'service', service
      service.debugger.debuggees.breakpoints.set
        auth: authClient
        debuggeeId: atom.config.get('cloud-debugger.debuggeeId')
        resource:
          action: 'CAPTURE'
          location:
            path: path
            line: line
        , (err, response) ->
          console.log 'breakpoint', err, response
          if err
            throw err
          atom.notifications.addInfo("Breakpoint set at #{path}:#{line}")

  getBreakpoint: (breakpointId) ->
    # TODO: need to call this with some kind of timeout to watch for data
    google.auth.getApplicationDefault (err, authClient) =>
      if err
        throw err
      if authClient.createScopedRequired && authClient.createScopedRequired()
        authClient = authClient.createScoped @_authScopes
      google.clouddebugger('v2').debugger.debuggees.breakpoints.get
        auth: authClient
        breakpointId: breakpointId
        debuggeeId: atom.config.get 'cloud-debugger.debuggeeId'
        , (err, response) ->
          console.log 'breakpoint', err, response
          if err
            throw err


  activate: (state) ->
    @projectsView = null
    @debuggeesView = null

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'cloud-debugger:toggle': =>
      @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'cloud-debugger:set-breakpoint': =>
      @setBreakpoint()

  deactivate: ->
    @subscriptions.dispose()
    @projectsView.destroy()
    @debuggeesView.destroy()

  serialize: ->
    # cloudDebuggerViewState: @cloudDebuggerView.serialize()

  toggle: ->
    @selectProject()
