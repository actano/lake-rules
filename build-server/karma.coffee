fs = require 'fs'
Promise = require 'bluebird'
mkdirp = Promise.promisify require 'mkdirp'
{join, resolve, dirname, basename} = require 'path'
helper = require './karma-helper'

TEST_REPORTS = process.env['TEST_REPORTS']

# TODO this should come from some config
HTML_TEMPLATE = resolve 'tools/karma-html-template.js'

writeResults = Promise.coroutine (reportFile, results, makeTarget) ->
    if results.suites?
        writer = require('./karma-jenkins-writer')
        pkgName = dirname(reportFile).replace /\//g, '.'
        className = basename reportFile, '.xml'

        xml = writer(results, "#{pkgName}.#{className}", makeTarget, helper.formatError)

        reportFile = join TEST_REPORTS, reportFile if TEST_REPORTS?
        yield mkdirp dirname reportFile
        yield fs.writeFileAsync reportFile, xml

    results.exitCode

karma = Promise.coroutine (makeTarget, srcFile, reportFile, assetspath, testFiles...) ->
    assets = [
        # karma-html-template needs to be loaded before testFiles
        HTML_TEMPLATE
        "#{assetspath}/**/*.js"
        "#{assetspath}/**/*.css"
    ]

    karmaServer = require './karma-server'
    results = yield karmaServer.run assets.concat testFiles

    writeResults reportFile, results, makeTarget

karmaWebpack = Promise.coroutine (target, src) ->
    src = src.split ' '
    karmaServer = require './karma-server'
    srcFiles = [HTML_TEMPLATE].concat src
    results = yield karmaServer.run srcFiles
    writeResults "#{src[0]}.xml", results, target

module.exports =
    karma: karma
    'karma-webpack': karmaWebpack

