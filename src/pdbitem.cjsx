_ = require 'underscore'
React = require 'react'
AppStore = require './appstore.coffee'
GLmolComponent = require './glmolcomponent.cjsx'

getAppState = ->
  return AppStore.getState()

PDBItem = React.createClass(

  getInitialState: ->
    state = getAppState()
    return {
      config: state.config
      items: state.results
      item: null
    }

  _onChange: () ->
    @setState getAppState()

  componentDidMount: () ->
    AppStore.addChangeListener(@_onChange)

  componentWillUnmount: () ->
    AppStore.removeChangeListener(@_onChange)

  pdbinfo: ->
    unless @state.item
      return (
        <div className="error">
          <h4>"Protein not found."</h4>
        </div>
        )
    if _.has @state.item, 'description'
      details = @state.item.description.PDBdescription.PDB.$
      return (
        <div key="pdb-info" className="pdb-info">
          <h4>We got infos</h4>
          <div>
            <p>
              Structure Id: <strong>{details.structureId}</strong><br/>
              From paper: <strong>{details.title}</strong><br/>
              Authors: <strong>{details.citation_authors}</strong><br/>
              Deposition date: <strong>{details.deposition_date}</strong><br/>
              Last updated: <strong>{details.last_modification_date}</strong><br/>
            </p>
          </div>
        </div>
        )
    else
     return (
      <div key="pdb-3d" className="pdb-info">
        <h3>loading... (derp a little derp)</h3>
      </div>)

  glmol: ->
    # ^ editorial note, this is a bad idea.  The logic should all be in GlmolComponent
    if @state.item
      if _.has @state.item, 'glmol'
        return(
          <div className="pdb-3d">
            <h4>3d infos!!</h4>
            <GLmolComponent pdbId={this.state.curPdbId} />
          </div>
          )
    return (
      <div className="pdb-3d">
        <h5>Nothing here...</h5>
      </div>)

  render: ->
    <div className="protein-page">
      {this.pdbinfo()}
      {this.glmol()}
    </div>
)


module.exports = PDBItem
