#!/usr/bin/env coffee

require('coffee-script') # required to run coffee tests
path = require('path')
fs = require('fs')
mkdirp = require('mkdirp')
Mocha = require('mocha')
program = require('commander')
istanbul = require 'istanbul'

program
    .usage('[options] <testfile ...>')
    .option('-p, --basePath <path>', 'path where lib directory is located')
    .option('-o, --reportOutDir <out>', 'report output directory')
    .parse(process.argv)

config = require("#{program.basePath}/lib/config")
config.set('app:port', config.get('app:test_coverage_port'))
webapp = require("#{program.basePath}/lib/webapp/webapp")

reporter = (options) ->
    (runner) ->
        Mocha.reporters[options.mocha_reporter.toUpperCase()].call(this, runner)

        runner.on 'end', ->
            coverage = global.__coverage__ || {}

            mkdirp.sync(program.reportOutDir)
            fs.writeFileSync(path.join(program.reportOutDir, "coverage.json"), JSON.stringify(coverage), 'utf8');

            collector = new istanbul.Collector()
            collector.add(coverage)

            options.istanbul_reporters.forEach((reporter) ->
                istanbul.Report.create(reporter, {dir: program.reportOutDir}).writeReport(collector, true))

            return

        return

mocha = new Mocha({
    reporter: reporter({
        mocha_reporter: 'tap'
        istanbul_reporters: ['text-summary', 'html', 'cobertura' ]
    })
})
mocha.files = program.args

webapp.start ->
    mocha.run process.exit

