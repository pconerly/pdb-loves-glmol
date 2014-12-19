_ = require 'underscore'
EventEmitter = require('events').EventEmitter
$ = require 'jquery'
Backbone = require 'backbone'
to_json = require('xmljson').to_json
GLmol = require './library/GLmol.js'

window.hmm = GLmol
console.log window.hmm

_life = {
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

  fetch: (query) ->
    console.log "fething #{query}"
    _life.results[query] = {
      glmol: new GLmol("glmol_#{query}", true)
    }
    console.log "glmol_#{query}"

    # _life.results[query].glmol = new GLmol("glmol_#{query}", true)

    $.ajax
      url: "http://www.rcsb.org/pdb/rest/describePDB?structureId=#{query}"
      method: 'GET'
      dataType: 'text' # it's xml, but we want the string
      error: (xhr, status, error) =>
        console.log "error"
        console.log error
      success: (data, status) =>
        if status is "success"
          jsondata = to_json data, (message, data) =>
            window.derp = data
            _life.results[query].description = data
            @emitChange()


    # interesting rest endpoints:
    # http://www.pdb.org/pdb/download/downloadFile.do?fileFormat=pdb&compression=NO&structureId=1B0B
    # http://www.rcsb.org/pdb/rest/describePDB?structureId=4hhb&json=true

  search: (value) ->
    Backbone.history.navigate "pdb-id/#{value}",
      trigger: true

  getState: ->
    return _life

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
