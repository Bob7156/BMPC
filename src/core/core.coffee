###*
 * @fileoverview メイン
 ###

{app, session, BrowserWindow} = require "electron"
path = require "path"
config = require "./config"
cache = require "./cache"

mainWindow = null

###*
 * ウィンドウを作成
 ###
createWindow = ->
  mainWindow = new BrowserWindow(
    width: 800,
    height: 600,
    title: "BlitzModderPC",
    icon: path.join(app.getAppPath(), "gui/img/image.jpg"),
    autoHideMenuBar: true,
    show: false
  )
  mainWindow.once("ready-to-show", ->
    mainWindow.show()
    return
  )
  mainWindow.loadURL("file://#{app.getAppPath()}/gui/index.html")
  mainWindow.on("closed", ->
    # guiの終了
    mainWindow = null
    return
  )
  return

###*
 * 起動準備完了
 ###
app.on("ready", ->
  # 設定とキャッシュの準備待ち
  Promise.all([config.init(), cache.init()]).then( ->
    createWindow()
    return
  ).catch((err) ->
    console.error err
    return
  )
)

app.on("window-all-closed", ->
  # キャッシュ削除
  session.defaultSession.clearCache( ->
    # アプリ終了
    app.quit()
  )
  return
)
