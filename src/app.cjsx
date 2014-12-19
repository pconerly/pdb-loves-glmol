$ = require 'jquery'
_ = require 'underscore'
Backbone = require("backbone")
React = require("react")
THREE = require 'three'
# for importing GLmol.js without making (many) changes to it.
window.$ = $
window.THREE = THREE

AppStore = require './appstore.coffee'
TopNav = require './topnav.cjsx'
PDBSearch = require './pdbsearch.cjsx'
PDBItem = require './pdbitem.cjsx'


Backbone.$ = $

WelcomePage = React.createClass(
  render: ->
    <span className="MyComponent">
      <p>Welcome to the WebGL protein viewer.
      </p>
      <PDBSearch />
    </span>
)


Router = Backbone.Router.extend 

  routes:
    "": "index"
    "search": "search"
    "pdb-id/:query": "pdbid"
    "backbone": "backbone"

  index: ->
    console.log "index"
    React.render(
      <TopNav/>,
      document.getElementById('admin')
      )
    React.render(
      <WelcomePage />,
      document.getElementById('content')
      )

  search: ->
    console.log "react"
    $(document).attr('title', 'react-of-life')

  pdbid: (query) ->
    AppStore.fetch(query)
    console.log "query: #{query}"
    React.render(
      <TopNav/>,
      document.getElementById('admin')
      )
    React.render(
      <PDBItem item={query} />,
      document.getElementById('content')
      )
    

new Router()
Backbone.history.start()
