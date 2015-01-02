_ = require 'underscore'
EventEmitter = require('events').EventEmitter
$ = require 'jquery'
Backbone = require 'backbone'
to_json = require('xmljson').to_json
GLmol = require './library/GLmol.js'

_life = {
  curPdbId: null
  config: {}
  results: {}
}


window._life = _life  # for debugging.

CHANGE_EVENT = 'changederp'

outer_iterate = ->
  AppStore.updateBoard()

AppStore = _.extend({}, EventEmitter::, 

  config: (config) ->
    _life.config = _.extend _life.config, config

  setPdbId: (query) ->
    _life.curPdbId = query
    @emitChange()

  fetch: (query) ->
    console.log "fething #{query}"
    _life.curPdbId = query

    @fetchDescription query
    @fetchPdb query

  fetchDescription: (query) ->
    _life.results[query] ?= {}

    $.ajax
      url: "http://www.rcsb.org/pdb/rest/describePDB?structureId=#{query}"
      method: 'GET'
      dataType: 'text' # it's xml, but we want the string
      crossDomain: true
      error: (xhr, status, error) =>
        console.log "error"
        console.log error
        @emitChange()
      success: (data, status) =>
        if status is "success"
          jsondata = to_json data, (message, data) =>
            if _.has data.PDBdescription, 'PDB'
              _life.results[query].description = data
            @emitChange()

  fetchPdb: (query) ->
    _life.results[query] ?= {}
    _life.results[query].glmol = new GLmol("glmol_#{query}", true)
    
    _life.results[query].glmol.initializeScene()

    $.ajax
      url: "http://www.pdb.org/pdb/files/#{query}.pdb"
      method: 'GET'
      dataType: 'text'
      crossDomain: true
      error: (xhr, status, error) =>
        console.log "error"
        console.log error
      success: (data, status) =>
        if status is "success"
          _life.results[query].pdbfile = data
          @emitChange()

    # interesting rest endpoints:
    # http://www.rcsb.org/pdb/rest/describePDB?structureId=4hhb&json=true

  search: (value) ->
    Backbone.history.navigate "pdb-id/#{value}",
      trigger: true

  getState: ->
    item = null
    if _.has _life.results, _life.curPdbId
      item = _life.results[_life.curPdbId]

    return _.extend _life, {
      item: item
    }

  emitChange: () ->
    @emit CHANGE_EVENT

  ###*
  @param {function} callback
  ###
  addChangeListener: (callback) ->
    @on CHANGE_EVENT, callback
    return

  ###*
  @param {function} callback
  ###
  removeChangeListener: (callback) ->
    @removeListener CHANGE_EVENT, callback
    return

)

module.exports = AppStore

