os = require 'os'
xmlbuilder = require 'xmlbuilder'

module.exports = (results, className, makeTarget, formatError) ->
    testsuites = xmlbuilder.create 'testsuites'
    for id, _suite of results.suites
        browser = _suite.browser
        result = browser.lastResult
        suite = testsuites.ele 'testsuite',
            name: browser.name
            'package': ''
            timestamp: _suite.timestamp
            id: 0
            hostname: os.hostname()
            make_target: makeTarget
            tests: result.total
            # Do NOT use result.error, karma sets this to true if there is no successful test, which makes all-skipped to be an error...
            errors: if result.disconnected || result.failures > 0 || _suite.errors.length then 1 else 0
            failures: result.failed
            time: (result.netTime || 0) / 1000

        suite.ele 'properties'
            .ele 'property',
                name: 'browser.fullName'
                value: browser.fullName

        for result in _suite.testcases
            testcase = suite.ele 'testcase',
                name: result.description
                time: (result.time || 0) / 1000
                classname: className
                'package': browser.name
                parentSuites: result.suite.join '|'

            testcase.ele 'skipped' if result.skipped

            unless result.success
                (testcase.ele 'failure', {type: ''}, formatError err) for err in result.log

        suite.ele 'system-out'
            .dat _suite.log.map((e) -> "#{e.type}: #{e.msg}").join '\n'

        suite.ele 'system-err'
            .dat _suite.errors.map((e) -> formatError e.stack || e.msg || e).join '\n'

    testsuites.end pretty: true
