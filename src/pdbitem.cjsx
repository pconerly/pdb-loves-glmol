_ = require 'underscore'
React = require 'react'
AppStore = require './appstore.coffee'

getAppState = ->
  return AppStore.getState()


PDBItem = React.createClass(

  getInitialState: ->
    state = getAppState()
    return {
      config: state.config
      items: state.results
      # item = state.results[@props.item]
    }

  getItem: ->
    if _.has(@state.items, @props.item)
      return @state.items[@props.item]
    else
      return null

  componentDidMount: () ->
    AppStore.addChangeListener(@_onChange)

  componentWillUnmount: () ->
    AppStore.removeChangeListener(@_onChange)

  _onChange: () ->
    # set time since last tick here?
    @setState getAppState()

  intervalChange: (e) ->
    AppStore.updateInterval e.target.value

  pdbinfo: ->
    item = @getItem()
    unless item
      return (
        <div className="error">
          <h4>"Protein not found."</h4>
        </div>
        )
    if _.has item, 'description'
      details = item.description.PDBdescription.PDB.$
      return (
        <div className="pdb-info">
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
      <div className="pdb-info">
        <h3>loading... (derp a little derp)</h3>
      </div>)

  glmol: ->
    item = @getItem()
    if item
      if _.has item, 'pdbfile'
        # call some shit. 
        # loadMoleculeStr(false, source)
        return(
          <div className="pdb-3d">
            <h4>3d infos!!</h4>
            <div id="glmol_{this.props.item}"></div>
          </div>
          )
    return (
      <div className="pdb-3d">
        <div id="glmol_{this.props.item}"></div>
      </div>)

  render: ->
    <div className="protein-page">
      {this.pdbinfo()}
      {this.glmol()}
    </div>
)


module.exports = PDBItem
