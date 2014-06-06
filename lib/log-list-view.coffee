Os = require 'os'
Path = require 'path'
fs = require 'fs'

{$$, BufferedProcess, SelectListView} = require 'atom'
OutputView = require './output-view'
StatusView = require './status-view'

module.exports =
class LogListView extends SelectListView

  dir = ->
    atom.project.getRepo().getWorkingDirectory()

  showCommitFilePath = ->
    Path.join Os.tmpDir(), "atom_git_plus_commit.diff"


  initialize: (@data) ->
    super
    @addClass 'overlay from-top'
    @parseData()

  parseData: ->
    @data = @data.split("\n")
    items = for item in @data
      continue if not item?
      tmp = item.match /([\w\d]{7});\|(.*);\|(.*);\|(.*)/
      {hash: tmp?[1], author: tmp?[2], title: tmp?[3], time: tmp?[4]}
    @setItems items
    atom.workspaceView.append this
    @focusFilterEditor()

  getFilterKey: -> 'title'

  viewForItem: (commit) ->
    $$ ->
      @li =>
        @div class: 'text-highlight text-huge', commit.title
        @div class: '', "#{commit.hash} by #{commit.author}"
        @div class: 'text-info', commit.time

  confirmed: ({hash}) ->
    args = ['show']
    args.push '--word-diff' if atom.config.get 'git-plus.wordDiff'
    args.push hash
    # args.push '--'

    new BufferedProcess
      command: 'git'
      args: args
      options:
        cwd: dir
      stderr: (data) ->
        console.log data
        new StatusView(type: 'alert', message: data.toString())
      stdout: (data) ->
        prepFile data

  prepFile = (text) ->
    fs.writeFileSync showCommitFilePath(), text, flag: 'w+'
    showFile()

  showFile = ->
    split = ''
    split = 'right'  if atom.config.get 'git-plus.openInPane'
    atom.workspace
      .open(showCommitFilePath(), split: split, activatePane: true)
