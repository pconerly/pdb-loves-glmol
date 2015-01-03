$ = require 'jquery'
_ = require 'underscore'
Backbone = require("backbone")
React = require("react")
THREE = require 'three'
# for importing GLmol.js without making (many) changes to it.
window.$ = $
window.THREE = THREE
ColorConverter = require './library/THREE.ColorConverter.js'

AppStore = require './appstore.coffee'
TopNav = require './topnav.cjsx'
PDBSearch = require './pdbsearch.cjsx'
PDBItem = require './pdbitem.cjsx'
SearchPage = require './searchpage.cjsx'

Backbone.$ = $

WelcomePage = React.createClass(
  render: ->
    <span className="MyComponent">
      <p>Welcome to the WebGL protein viewer.
      </p>
      <PDBSearch />
      {this.props.children}
    </span>
)


Router = Backbone.Router.extend 

  routes:
    "": "index"
    "search/:term": "search"
    "pdb-id/:query": "pdbid"
    "backbone": "backbone"

  index: ->
    AppStore.setPdbId null
    React.render(
      <TopNav/>,
      document.getElementById('admin')
      )
    React.render(
      <WelcomePage />,
      document.getElementById('content')
      )

  search: (term) ->
    AppStore.setPdbId null
    AppStore.search(encodeURIComponent(term))
    React.render(
      <TopNav/>,
      document.getElementById('admin')
      )
    React.render(
      <WelcomePage>
        <SearchPage term={term}/>
      </WelcomePage>,
      document.getElementById('content')
      )

  pdbid: (query) ->
    AppStore.fetch query
    React.render(
      <TopNav/>,
      document.getElementById('admin')
      )
    React.render(
      <PDBItem />,
      document.getElementById('content')
      )
    

new Router()
Backbone.history.start()
