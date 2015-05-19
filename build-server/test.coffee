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

prepareTest = Promise.coroutine (makeTarget, reportFile) ->
    yield mkdirp path.dirname reportFile
    env =
        MAKE_TARGET: makeTarget

    if TEST_REPORTS?
        prefix = path.join TEST_REPORTS, 'x'
        prefix = prefix.substring 0, prefix.length-1
        if reportFile.substring(0, prefix.length) is prefix
            reportFile = reportFile.substring prefix.length
            env.PREFIX = prefix
    env.REPORT_FILE = reportFile

    e = yield existsAsync reportFile
    yield unlink reportFile if e

    return env

processTest = Promise.coroutine (child, reportFile) ->
    code = yield new Promise (resolve) ->
        child.on 'exit', (code, signal) ->
            unless code?
                code = CODE_SIGNALLED
            resolve(code)

    if yield existsAsync reportFile
        yield unlink reportFile unless code is 0
    else
        code = CODE_REPORT_MISSING

    return code


module.exports = {prepareTest, processTest}
