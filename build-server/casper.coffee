path = require 'path'
{spawn} = require 'child_process'
Promise = require 'bluebird'

# TODO come over to lake-rules
BROWSER_WRAPPER = 'lib/testutils/browser-wrapper.coffee'

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

    env = {}
    reportFile = yield prepareTest makeTarget, reportFile, env
    env.PATH = buildPath()
    env.LC_ALL = 'en_US'

    # TODO don't use CLI
    child = spawn casperjs, [BROWSER_WRAPPER, srcFile], {env, stdio: 'inherit'}

    processTest child, reportFile

module.exports = {casper}
