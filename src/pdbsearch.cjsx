React = require "react"
Input = require('react-bootstrap').Input
AppStore = require './appstore.coffee'

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
      placeholder="peanut, human, 1bzw, 2por, 4hhb"
      label="Search the PDB"
      help="Enter a PDBid or a search keyword for the title of a paper. "
      hasFeedback
      ref="input"
      groupClassName="group-class"
      wrapperClassName="wrapper-class"
      labelClassName="label-class"
      onChange={this.handleChange}
      onKeyDown={this.listenForReturn} />
)

module.exports = PDBSearch