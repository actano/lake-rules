path = require 'path'
{spawn} = require 'child_process'
Promise = require 'bluebird'

buildPath = ->
    p = process.env['PATH']
    # Find phantomjs npm package and add it's bin to path
    try
        phantomjs = require.resolve 'phantomjs/bin/phantomjs'
        return "#{p}#{path.delimiter}#{path.dirname phantomjs}"
    catch ignore
        # TODO shall we error-log here something?
        return p

casper = Promise.coroutine (makeTarget, srcFile, reportFile) ->
    {prepareTest, processTest} = require './test'
    casperjs = require.resolve 'casperjs/bin/casperjs'

    env = yield prepareTest makeTarget, reportFile
    env.PATH = buildPath()
    env.LC_ALL = 'en_US'

    # TODO don't use CLI
    child = spawn casperjs, ['lib/testutils/browser-wrapper.coffee', srcFile], {env, stdio: 'inherit'}

    processTest child, reportFile

module.exports = {casper}
