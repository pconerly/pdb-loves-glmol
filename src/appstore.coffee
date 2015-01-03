_ = require 'underscore'
EventEmitter = require('events').EventEmitter
$ = require 'jquery'
Backbone = require 'backbone'
to_json = require('xmljson').to_json
GLmol = require './library/GLmol.js'

_life = {
  curPdbId: null
  config: {}
  results: {} # keys: pdb-id
  searches: {} # keys: search string
  explored: {} # proteins we've actually navigated to
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
    if query
      _life.explored[query] = true
    @emitChange()

  fetch: (query) ->
    console.log "fething #{query}"
    @setPdbId query

    @fetchDescription query
    @fetchPdbFile query

  fetchDescription: (query) ->
    _life.results[query] ?= {}

    # if we've already found it, skip this.
    if _.has(_life.results[query], 'description')
      @emitChange()
      return

    @getPdbDescription query, (data, status) =>
      if status is "success"
        jsondata = to_json data, (message, data) =>
          if _.has data.PDBdescription, 'PDB'
            _life.results[query].description = data
          @emitChange()

  getPdbDescription: (query, callback) ->
    $.ajax
      url: "http://www.rcsb.org/pdb/rest/describePDB?structureId=#{query}"
      method: 'GET'
      dataType: 'text' # it's xml, but we want the string
      crossDomain: true
      error: (xhr, status, error) =>
        console.log "error"
        console.log error
        @emitChange()
      success: callback

  fetchPdbFile: (query) ->
    _life.results[query] ?= {}

    unless _.has(_life.results[query], 'glmol')
      _life.results[query].glmol = new GLmol("glmol_#{query}", true)
      _life.results[query].glmol.initializeScene()

    # if we've already found it, skip this.
    if _.has(_life.results[query], 'pdbfile')
      @emitChange()
      return

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

  search: (query) ->

    # check for existing found protein
    if _.has(_life.results, query)      
      Backbone.history.navigate "#pdb-id/#{query}",
        trigger: true
      return

    else
      # search for PDB id
      @getPdbDescription query, (data, status) =>
        if status isnt 'success'
          # it isn't a success or...
          @generalSearch(query)
        else
          jsondata = to_json data, (message, data) =>
            unless _.has data.PDBdescription, 'PDB'
              #.. it's a blank file.
              @generalSearch(query)
            else
              _life.results[query] = {}
              _life.results[query].description = data
              Backbone.history.navigate "pdb-id/#{query}",
                trigger: true
              return

  generalSearch: (query) ->
    if _.has(_life.searches, query)
      return

    $.ajax
      url: "http://www.rcsb.org/pdb/rest/search/?req=browser"
      # url: "http://peterproxy.flaregun.io/pdb/rest/search/?req=browser" ## my dakka proxy
      method: 'POST'
      dataType: 'text'
      data: """
        <?xml version="1.0" encoding="UTF-8"?>
        <orgPdbQuery>
        <queryType>org.pdb.query.simple.StructTitleQuery</queryType>
        <description>StructTitleQuery: struct.title.comparator=contains struct.title.value=#{query} </description>
        <struct.title.comparator>contains</struct.title.comparator>
        <struct.title.value>#{query}</struct.title.value>
        </orgPdbQuery>
        """
      error: (xhr, status, error) =>
        console.log "error"
        console.log error
      success: (data, status) =>
        data = data.replace(/^\s+|\s+$/g, "").split('\n')
        data = data[0..-2] # we don't need the last item.

        for d in data
          _life.results[d] = {}

        _life.searches[query] = data
        Backbone.history.navigate "search/#{encodeURIComponent(query)}",
          trigger: true

        @emitChange()


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


# Other interesting PDB queries

# data: """
#   <?xml version="1.0" encoding="UTF-8"?>

#   <orgPdbQuery>
#   <queryType>org.pdb.query.simple.StructDescQuery</queryType>
#   <description>StructDescQuery: entity.pdbx_description.comparator=contains entity.pdbx_description.value=#{query} </description>
#   <entity.pdbx_description.comparator>contains</entity.pdbx_description.comparator>
#   <entity.pdbx_description.value>#{query}</entity.pdbx_description.value>
#   </orgPdbQuery>
#   """
