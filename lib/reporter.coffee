# Adapted from https://github.com/atom/metrics

https = require 'https'
path = require 'path'
querystring = require 'querystring'
_ = require 'lodash'

module.exports =
  class Reporter
    @sendEvent: (category, name, value) ->
      params =
        t: 'event'
        ec: category
        ea: name
        ev: value ? 0

      @send(params)

    @sendTiming: (category, name, value) ->
      params =
        t: 'timing'
        utc: category
        utv: name
        utt: value

      @send(params)

    @send: (params) ->
      return unless atom.config.get 'scope-inspector.trackUsageMetrics'
      _.extend(params, @defaultParams())
      @request
        method: 'POST'
        hostname: 'www.google-analytics.com'
        path: "/collect?#{querystring.stringify(params)}"
        headers:
          'User-Agent': navigator.userAgent

    @request: (options) ->
      request = https.request(options)
      request.on 'error', (err) -> # This prevents errors from going to the console
      request.end()

    @defaultParams: ->
      v: 1
      tid: "UA-30120906-4"
      cid: atom.config.get('scope-inspector.userId')
      an: 'voldenburg.com'
      av: atom.getVersion()
      sr: "#{screen.width}x#{screen.height}"
