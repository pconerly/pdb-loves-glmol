_ = require 'underscore'
React = require 'react'
AppStore = require './appstore.coffee'

getAppState = ->
  return AppStore.getState()

GLmolComponent = React.createClass(

  getInitialState: ->
    state = getAppState()
    return {
      config: state.config
      items: state.results
      item: null
      curPdbId: null
    }

  _onChange: () ->
    if @isMounted()
      @setState getAppState()

  componentDidMount: () ->
    @_onChange()
    AppStore.addChangeListener(@_onChange)

  componentWillUnmount: () ->
    AppStore.removeChangeListener(@_onChange)

  _forceReloadDebug: ->
    @componentDidUpdate()

  render: ->
    if @state.curPdbId
      <div class="glmol_parent">
        <button onClick={this._forceReloadDebug}>Reload this shit</button>
        <div id={this.containerId()} className='glmol_container'>
        </div>
      </div>
    else
      <div></div>

  containerId: ->
    "glmol_#{@state.curPdbId}"

  componentDidUpdate: () ->
    console.log "glmol component updated"
    # The actual rendering for webgl protein viewer
    if @isMounted() and @state.curPdbId and _.has(@state.item, 'glmol') and _.has(@state.item, 'pdbfile')
      # clean up the container
      $("##{@containerId()}").empty()

      # reset the element
      @state.item.glmol.setElement(@containerId())

      # and render
      # @state.item.glmol.loadMoleculeStr(false, window.pdbfile) # @state.item.pdffile)
      @state.item.glmol.loadMoleculeStr(false, @state.item.pdbfile)
      @state.item.glmol.enableMouse()
)



module.exports = GLmolComponent
