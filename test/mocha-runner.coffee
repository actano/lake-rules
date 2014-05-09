#!/usr/bin/env coffee

Mocha = require 'mocha'
istanbul = require 'istanbul'
fs = require 'fs'
path = require 'path'
sternchen = require 'sternchen'

class Reporter extends sternchen
    constructor: (runner) ->
        super runner

        runner.on 'end', ->
            coverage = global.__coverage__ || {}

            fs.writeFileSync(path.join("coverage", "coverage.json"), JSON.stringify(coverage), 'utf8');

            collector = new istanbul.Collector()
            collector.add(coverage)

            ['text-summary', 'html', 'cobertura' ].forEach((reporter) ->
                istanbul.Report.create(reporter, {dir: 'coverage'}).writeReport(collector, true))

            return

        return

mocha = new Mocha({
    reporter: Reporter
})

mocha.files = process.argv.slice 1
mocha.run process.exit
