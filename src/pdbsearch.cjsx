React = require "react"
Input = require('react-bootstrap').Input
AppStore = require './appstore.coffee'


getLifeState = ->
  return LifeStore.getState()

PDBSearch = React.createClass(
  getInitialState: ->
    value: ""

  handleChange: ->
    
    # This could also be done using ReactLink:
    # http://facebook.github.io/react/docs/two-way-binding-helpers.html
    @setState value: @refs.input.getValue()
    return

  listenForReturn: (e) ->
    if e.key is 'Enter'
      AppStore.search @state.value

  render: ->
    <Input
      type="text"
      value={this.state.value}
      placeholder="4hhb"
      label="Search the PDB"
      help="Validates based on string length."
      hasFeedback
      ref="input"
      groupClassName="group-class"
      wrapperClassName="wrapper-class"
      labelClassName="label-class"
      onChange={this.handleChange}
      onKeyDown={this.listenForReturn} />
)

module.exports = PDBSearch