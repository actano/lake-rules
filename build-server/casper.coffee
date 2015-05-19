path = require 'path'
{spawn} = require 'child_process'
Promise = require 'bluebird'
casperjs = require.resolve 'casperjs/bin/casperjs'
mkdirp = Promise.promisify require 'mkdirp'
{exists, existsSync, unlink} = require('fs')

unlink = Promise.promisify unlink

{TEST_REPORTS,PATH,FAILED_TEST_TARGETS_FILE}=process.env

CODE_SIGNALLED = 98
CODE_REPORT_MISSING = 2

# Find phantomjs npm package and add it's bin to path
try
    phantomjs = require.resolve 'phantomjs/bin/phantomjs'
    PATH += "#{path.delimiter}#{path.dirname phantomjs}"
catch ignore
    # TODO shall we error-log here something?

existsAsync = (path) ->
    new Promise (resolve) -> exists path, resolve

casper = Promise.coroutine (makeTarget, srcFile, reportFile) ->
    yield mkdirp path.dirname reportFile
    env =
        PATH: PATH
        LC_ALL: 'en_US'
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

    # TODO don't use CLI
    child = spawn casperjs, ['lib/testutils/browser-wrapper.coffee', srcFile], {env, stdio: 'inherit'}

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

module.exports = {casper}
