###*
 * @fileoverview 設定関係のメソッド
 ###

fs = require "fs-extra"
path = require "path"
{app} = require "electron"
denodeify = require "denodeify"
util = require "./util"
os = require "os"

###*
 * 設定をおくフォルダ
 * @const
 ###
CONFIG_FOLDER_PATH = path.join(app.getPath("userData"), "config")
GENERAL_CONFIG_PATH = path.join(CONFIG_FOLDER_PATH, "general.json")
LANG_LIST = [
  "ja"
  "en"
  "ru"
  "zh_TW"
  "zh_CN"
]
PLATFORM_LIST = [
  "w"
  "m"
  "a"
  "i"
]
BLITZ_PATH =
  WIN64: "C:\\Program Files (x86)\\Steam\\steamapps\\common\\World of Tanks Blitz"
  WIN32: "C:\\Program Files\\Steam\\steamapps\\common\\World of Tanks Blitz"
  MACSTEAM: path.join(os.homedir(), "Library/Application Support/Steam/SteamApps/common/World of Tanks Blitz/World of Tanks Blitz.app/Contents/Resources/")
  MACSTORE: "/Applications/World of Tanks Blitz.app/Contents/Resources/"

ensureFile = denodeify(fs.ensureFile)
readJson = denodeify(fs.readJson)

###
 * 設定のデータ
 ###
data = {}
###
 * dataの初期値
 * @const
 ###
DEFAULT_DATA =
  repos: ["http://subdiox.com/repo"]
  localRepos: []
  debugRepo: ""
  appliedMods: []
  lang: "ja"
  blitzPathType: "folder"

do ->
  DEFAULT_DATA.platform = util.getPlatform()
  switch DEFAULT_DATA.platform
    when "w"
      switch os.arch()
        when "x64" then DEFAULT_DATA.blitzPath = BLITZ_PATH.WIN64
        when "ia32" then DEFAULT_DATA.blitzPath = BLITZ_PATH.WIN32
      DEFAULT_DATA.blitzPathRadio = "win"
    when "m"
      DEFAULT_DATA.blitzPath = BLITZ_PATH.MACSTEAM
      DEFAULT_DATA.blitzPathRadio = "macsteam"
    else
      DEFAULT_DATA.blitzPath = "World of Tanks Blitz"
      DEFAULT_DATA.blitzPathRadio = "other"
  return

getDefaultWinBlitzPath = ->
  switch os.arch()
    when "x64" then return BLITZ_PATH.WIN64
    when "ia32" then return BLITZ_PATH.WIN32

###
 * エラー出力
 * @private
 ###
_outputError = (err) ->
  console.error("Error: #{err}") if err?
  return

###
 * 設定更新
 * @private
 ###
_update = ->
  fs.outputJson(GENERAL_CONFIG_PATH, data, _outputError)
  return

###
 * 設定をメモリに展開
 * @constructor
 ###
init = ->
  return ensureFile(GENERAL_CONFIG_PATH).then( ->
    return readJson(GENERAL_CONFIG_PATH, throws: false)
  ).then( (content) ->
    data = Object.assign({}, DEFAULT_DATA)
    if content?
      data = Object.assign(data, content)
    else
      machineLang = app.getLocale()
      switch true
        when machineLang is "ja" then data.lang = "ja"
        when machineLang is "ru" then data.lang = "ru"
        when machineLang is "zh-TW" then data.lang = "zh_TW"
        when machineLang is "zh-CN" then data.lang = "zh_CN"
        when machineLang.includes("en") then data.lang = "en"
        when machineLang.includes("zh") then data.lang = "zh_CN"
        else data.lang = "en"
    _update()
  )

get = (a) ->
  return data[a]

set = (a, b) ->
  data[a] = b
  _update()
  return

add = (a, b) ->
  data[a].push(b)
  _update()
  return

remove = (a, b) ->
  for v, i in data[a] when JSON.stringify(v) is JSON.stringify(b)
    data[a].splice(i, 1)
  _update()
  return

reset = ->
  data = Object.assign({}, DEFAULT_DATA)
  _update()
  return

module.exports =
  GENERAL_CONFIG_PATH: GENERAL_CONFIG_PATH
  LANG_LIST: LANG_LIST
  PLATFORM_LIST: PLATFORM_LIST
  BLITZ_PATH: BLITZ_PATH
  getDefaultWinBlitzPath: getDefaultWinBlitzPath
  data: data
  init: init
  get: get
  set: set
  add: add
  remove: remove
  reset: reset
