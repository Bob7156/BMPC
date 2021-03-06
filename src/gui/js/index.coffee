{remote, shell} = require "electron"
{app} = remote
semver = remote.require("semver")
plistInfo = remote.require("./plistInfo")
config = remote.require("./config")
request = remote.require("./request")
lang = remote.require("./lang")
util = remote.require("./util")

langTable = lang.get()
transEle = document.getElementsByClassName("translate")
for te in transEle
  te.textContent = langTable[te.dataset.key]

formatRepoName = (name) ->
  m = /^https?:\/\/github\.com\/(.+?)\/(.+?)\/raw\/master$/.exec(name)
  if m?
    return "#{m[1]}/#{m[2]}"
  m = /^https?:\/\/(.+?)\.github\.io\/(.+?)$/.exec(name)
  if m?
    return "#{m[1]}/#{m[2]}"
  m = /^https?:\/\/(.+?)$/.exec(name)
  if m?
    return m[1]
  return name

Vue.component("repo",
  template: """
            <li class=\"list-group-item\">
              <a :href=\"url\">
                <span v-if="hasinfo">{{infoname}} <sub><small>{{infomaintainer}}</small></sub> ({{formatedName}})</span>
                <span v-else>{{formatedName}}</span>
              </a>
            </li>
            """
  props: ["name", "repotype", "hasinfo", "infoname", "infomaintainer"]
  computed:
    formatedName: ->
      return formatRepoName(@name)
    url: ->
      return "./repo.html?type=#{@repotype}&path=#{encodeURIComponent(@name)}"
  created: ->
    @getInfo()
    return
  methods:
    getInfo: ->
      return plistInfo.get(type: @repotype, name: @name).then( (obj) =>
        @hasinfo = true
        @infoname = obj.name
        @infomaintainer = obj.maintainer
      ).catch( =>
        @hasinfo = false
      )
)
Vue.component("debug-repo",
  template: "<a href=\"./debug_repo.html\">{{formatedName}}</a>"
  props: ["name"]
  computed:
    formatedName: ->
      return formatRepoName(@name)
)
new Vue(
  el: "#repo"
  data:
    remoteRepos: config.get("repos")
    localRepos: config.get("localRepos")
    debugRepo: config.get("debugRepo")
)

request.getLastestVersion().then( (newVer) ->
  if semver.gt(newVer, app.getVersion())
    for tag in document.getElementsByClassName("newVersion")
      tag.textContent = newVer
    $("#update").removeClass("hidden")
  return
)
$("#updateLink").on("click", ->
  shell.openExternal("https://github.com/BlitzModder/BMPC/releases")
  return
)

if config.get("blitzPathType") is "file" or !util.blitzExists()
  $("#play").remove()
else
  document.getElementById("play").addEventListener("click", ->
    util.openBlitz()
    return
  )
