path = require 'path'
Promise = require 'bluebird'
mkdirp = Promise.promisify require 'mkdirp'
{exists, unlink} = require('fs')
{prepareTest} = require './test'

unlink = Promise.promisify unlink

{TEST_REPORTS}=process.env
CODE_SIGNALLED = 98
CODE_REPORT_MISSING = 2

existsAsync = (path) ->
    new Promise (resolve) -> exists path, resolve

prepareTest = Promise.coroutine (makeTarget, reportFile, env) ->
    if env?
        for k, v in process.env
            env[k] = v
    else
        env = process.env

    yield mkdirp path.dirname reportFile
    env['MAKE_TARGET'] = makeTarget
    env['REPORT_FILE'] = reportFile
    if TEST_REPORTS?
        env['PREFIX'] = TEST_REPORTS
        reportFile = path.join TEST_REPORTS, reportFile

    e = yield existsAsync reportFile
    yield unlink reportFile if e

    return reportFile

exitCallback = ->
    cb = null
    promise = new Promise (resolve) ->
        cb = (code) ->
            code = CODE_SIGNALLED unless code?
            resolve code

    cb.Promise = promise
    return cb

cleanup = Promise.coroutine (reportFile, code) ->
    if yield existsAsync reportFile
        yield unlink reportFile unless code is 0
    else
        console.error 'Test Report file %s missing', reportFile
        code = CODE_REPORT_MISSING

    return code

processTest = Promise.coroutine (child, reportFile) ->
    cb = exitCallback()
    child.on 'exit', cb
    code = yield cb.Promise
    return cleanup reportFile, code

prefix = (reportFile) ->
    if TEST_REPORTS?
        _prefix = path.join TEST_REPORTS, 'x'
        _prefix = _prefix.substring 0, _prefix.length-1
        if reportFile.substring(0, _prefix.length) is _prefix
            return _prefix

plainReportFile = (reportFile) ->
    _prefix = prefix reportFile
    return reportFile unless _prefix?
    reportFile.substring _prefix.length

module.exports = {prepareTest, processTest, cleanup, exitCallback, plainReportFile, prefix}
