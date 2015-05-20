path = require 'path'
Promise = require 'bluebird'
mkdirp = Promise.promisify require 'mkdirp'
{exists, unlink} = require('fs')
{prepareTest} = require './test'

unlink = Promise.promisify unlink

{TEST_REPORTS}=process.env
CODE_SIGNALLED = 98
CODE_REPORT_MISSING = 2
FAIL_FAST = process.env['FAIL_FAST'] isnt '0'

existsAsync = (path) ->
    new Promise (resolve) -> exists path, resolve

prepareTest = Promise.coroutine (makeTarget, reportFile, env = {}) ->
    for k, v in process.env
        env[k] = v

    env['MAKE_TARGET'] = makeTarget
    env['REPORT_FILE'] = reportFile
    if TEST_REPORTS?
        env['PREFIX'] = TEST_REPORTS
        reportFile = path.join TEST_REPORTS, reportFile

    yield mkdirp path.dirname reportFile
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
        return 0 unless FAIL_FAST
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

module.exports = {prepareTest, processTest}
