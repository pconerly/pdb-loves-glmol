React = require "react"
ListGroup = require('react-bootstrap').ListGroup
ListGroupItem = require('react-bootstrap').ListGroupItem

AppStore = require './appstore.coffee'


getAppState = ->
  return AppStore.getState()

SearchResults = React.createClass(

  getInitialState: ->
    state = getAppState()
    return state

  _onChange: () ->
    @setState getAppState()

  componentDidMount: () ->
    AppStore.addChangeListener(@_onChange)

  componentWillUnmount: () ->
    AppStore.removeChangeListener(@_onChange)

  ourSearchResults: ->
    console.log @props.term
    @state.searches[@props.term]

  render: ->
    searchResults = @ourSearchResults()

    if !searchResults or searchResults.length is 0
      resultsList = <h2>No items found.</h2>
    else
      listItems = []
      for item in searchResults
        url = "#pdb-id/#{item}"
        listItems.push(<ListGroupItem key={item} href={url}>{item}</ListGroupItem>)

      resultsList = (
        <ListGroup>
          {listItems}
        </ListGroup>)

    <div className="searchresults">
      <h2>Results for {this.props.term}</h2>
      {resultsList}
    </div>
)

module.exports = SearchResults