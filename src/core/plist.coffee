fs = require "fs-extra"
path = require "path"
plist = require "plist"
Promise = require "promise"
request = require "./request"
cache = require "./cache"

readFile = Promise.denodeify(fs.readFile)

###*
 * データ
 ###
data = {}

###*
 * エラー出力
 * @private
 ###
_outputError = (err) ->
  console.error("Error: #{err}") if err?
  return

###*
 * 使いやすいように変形します
 * @param {Object} plist.parse()で変換したもの
 * @return {Object}
 ###
parse = (plistObj) ->
  obj = {}
  for key, val of plistObj
    [name, id] = key.split(":")
    obj[name] = {}
    for k, v of val
      [n, i] = k.split(":")
      obj[name][n] = {}
      for k_ of v
        [n_, i_] = k_.split(":")
        obj[name][n][n_] = "#{id}.#{i}.#{i_}"
  return obj

###*
 * plistを取得してパースしたものを返します
 * @param {"remote"|"local"} repoType
 * @param {string} repoName
 * @param {string} lang
 * @param {boolean} force キャッシュを無視して元ファイルを取得するか 既定値は"false"
 * @return {Object} plistのオブジェクト
 ###
get = ({type: repoType, name: repoName}, lang, force = false) ->
  return new Promise( (resolve, reject) ->
    if data[repoName]?[lang]? and !force
      resolve(data[repoName][lang])
      return
    cache.getStringFile(repoName, "#{lang}.plist", force).then( (content) ->
      data[repoName] = {} if !data[repoName]?
      data[repoName][lang] = parse(plist.parse(content))
      resolve(data[repoName][lang])
      return
    , (err) ->
      if repoType is "remote"
        request.getFromGitHub(repoName, "#{lang}.plist").then( (content) ->
          string = content.toString()
          cache.setStringFile(repoName, "#{lang}.plist", string)
          data[repoName] = {} if !data[repoName]?
          data[repoName][lang] = parse(plist.parse(string))
          resolve(data[repoName][lang])
          return
        , (err) ->
          reject(err)
          return
        )
      else if repoType is "local"
        readFile(path.join(repoName, "#{lang}.plist"), "utf8").then( (res) ->
          cache.setStringFile(repoName, "#{lang}.plist", res)
          data[repoName] = {} if !data[repoName]?
          data[repoName][lang] = parse(plist.parse(res))
          resolve(data[repoName][lang])
          return
        , (err) ->
          reject(err)
          return
        )
      else
        reject()
      return
    )
  )

module.exports =
  get: get
