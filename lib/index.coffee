# see http://r.va.gg/2014/06/why-i-dont-use-nodes-core-stream-module.html for
# why we use readable-stream
Readable = require('readable-stream').Readable
request = require 'request'
JSONStream = require 'JSONStream'

###*
 * Make a request for a Vine page, parse the response, and get all the posts. It
   seems that either the `page` or `anchor` parameters (or both) can be provided
   in the request, and the same result will be returned. The anchor has nothing
   to do with the ids of the posts, but I assume that supplying it prevents the
   query from getting screwed up if another post is added while we are
   paginating through the results.
 * @param {String} username
 * @param {String} anchor
 * @return {Readable} A stream of posts
###
getPostPage = (userId, maxId) ->
  outStream = JSONStream.parse('data.records.*')
  request.get(
    uri: "https://vine.co/api/timelines/users/#{userId}"
    qs: {anchor: maxId}
  ).on('response', (resp) ->
    if resp.statusCode is 200
      # This section is a hack to fix the fact that Vine put 19/+ digit ID
      # numbers inside of JSON without quoting or something to prevent them
      # from being rounded. we collect the whole stream & edit their JSON with a
      # regex. This also makes the JSONStream part pretty useless, but I don't
      # want to change the interface just for this hack.
      out = ''
      resp.on('data', (data) ->
        out += data
      ).on('end', ->
        outStream.write(
          out.replace(/"postId": ([0-9]+)/g, '"postId":"$1"')
        )
        outStream.end()
      )
    else
      throw new Error("Vine returned status code: #{resp.statusCode} for
      user '#{userId}' and anchor: '#{maxId}'")
  )
  return outStream

class VinePosts extends Readable
  _lock: false
  _maxPostId: undefined

  constructor: (@username) ->
    # remove the explicit HWM setting when github.com/nodejs/node/commit/e1fec22
    # is merged into readable-stream
    super(highWaterMark: 16, objectMode: true)

  _read: =>
    # prevent additional requests from being made while one is already running
    if @_lock then return
    @_lock = true

    # we hold one post in a buffer because we need something to send directly
    # after we turn off the lock
    lastPost = undefined
    getPostPage(@username, @_maxPostId).on('data', (res) =>
      @_maxPostId = res.postId # only the last one really matters
      tags = []
      for entity in res.entities
        if entity.type is 'tag' then tags.push(entity.title)

      if lastPost? then @push(lastPost)
      lastPost =
        username: @username
        _id: res.postId
        loop: res.loops.count
        comment: res.comments.count
        repost: res.reposts.count
        like: res.likes.count
        time: (new Date(res.created)).getTime() / 1000
        text: res.description
    ).on('end', =>
      @_lock = false
      if lastPost?
        @push(lastPost)
      else
        # the request returned no posts
        @push(null)
    )

module.exports = VinePosts
