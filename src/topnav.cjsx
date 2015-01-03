_ = require 'underscore'
React = require 'react'

# imports for the navbar
Navbar = require('react-bootstrap').Navbar
Nav = require('react-bootstrap').Nav
NavItem = require('react-bootstrap').NavItem
DropdownButton = require('react-bootstrap').DropdownButton
MenuItem = require('react-bootstrap').MenuItem

AppStore = require './appstore.coffee'

getAppState = ->
  return AppStore.getState()


TopNav = React.createClass(

  getInitialState: ->
    state = getAppState()
    return {
      config: state.config
      items: state.results
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

  render: ->

    pdbs = []
    keys = _.keys @state.items
    keys = _.sortBy keys, (key) ->
      key  # sort by key

    for key in keys
      primary = ''
      if key is @state.curPdbId
        primary = 'primary'
      pdbs.push(<MenuItem eventKey={key} href="#pdb-id/#{key}" 
        className={primary} key={key} >{key}</MenuItem>)

    disabled = ''
    if keys.length is 0
      # `btn` class is required because `disabled` doesn't work on it's own. Also, hacky.
      disabled = 'btn disabled'

    <Navbar>
      <Nav>
        <NavItem eventKey={1} href="#">Home</NavItem>
        <DropdownButton eventKey={3} title="Proteins explored:" className={disabled}>
          {pdbs}
        </DropdownButton>
      </Nav>
    </Navbar>
)


module.exports = TopNav

