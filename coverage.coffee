# Std library
path = require 'path'
fs = require 'fs'

# Third party
{_} = require 'underscore'

# Local dep
{concatPaths} = require "./rulebook_helper"

exports.title = 'coverage'
exports.description = "coffe coverage and JS coverage with istanbul"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    # These paths are all feature specific
    buildPath = path.join featurePath, lake.featureBuildDirectory # lib/foobar/build
    coverageReport = path.join buildPath, lake.coverageReport # lib/foobar/build/coverage/report

    # project root relative paths
    projectRoot = path.resolve lake.lakePath, ".." # project root
    coveragePath = path.join lake.coveragePath, featurePath # build/coverage/lib/foobar 
    uninstrumentedPath = path.join lake.uninstrumentedPath, featurePath # build/coverage/uninstrumented_js_files/lib/foobar

    # COVERAGE TARGET

    # CoffeeCoverage
    # create parallel path: lib/foobar-coverage/
    coffeeCoveragePath = path.join featurePath, "..", "#{path.basename(featurePath)}-coverage"

    coverageIntegration = []
    coverageUnit = []
    if manifest.integrationTests?.mocha?
        coverageIntegration = concatPaths manifest.integrationTests.mocha, {pre: coffeeCoveragePath}
    if manifest.server?.tests?
        coverageUnit = concatPaths manifest.server.tests, {pre: coffeeCoveragePath}

    coffeeCoverTests =
        unit: coverageUnit
        integration: coverageIntegration
        all: coverageUnit.concat coverageIntegration

    coverageInitFile = path.join coffeeCoveragePath, 'init.js'

    # do coffee coverage for each type (unit, integration, all)
    for testType, testFiles of coffeeCoverTests
        ((testType, testFiles) ->
            coffeeCoverageReportPath = path.join coffeeCoveragePath, "$(COFFEE_COVERAGE_REPORT_PREFIX)#{testType}.html"
            reportCopyPath = path.join(buildPath, path.basename(coffeeCoverageReportPath))
            coffeeCoverageGlobalReportPath = path.join lake.coveragePath, "$(COFFEE_COVER_GLOBAL_REPORT)#{testType}.html"
            if testFiles.length > 0
                rb.addToGlobalTarget "coffee-coverage-#{testType}", rb.addRule "coffee-coverage-#{testType}", ["coffee-coverage"], ->
                    targets: path.join featurePath, "coffee_cover_#{testType}"
                    dependencies: [
                        path.join featurePath, "#{testType}_test"
                    ]
                    actions: [
                        "mkdir -p #{path.join coffeeCoveragePath, 'test'}"
                        "cp -r #{path.join featurePath, 'test', '*'} #{path.join coffeeCoveragePath, 'test'}"
                        "$(NODE_BIN)/coffeeCoverage --initfile #{coverageInitFile} --exclude $(COFFEE_COVERAGE_EXCLUDE) --path relative #{featurePath} #{coffeeCoveragePath}"
                        "$(MOCHA) --require #{coverageInitFile} -R $(COFFEE_COVERAGE_REPORTER) $(MOCHA_COMPILER) #{testFiles.join ' '} > #{coffeeCoverageReportPath}"
                        "mkdir -p #{buildPath}"
                        "cp #{coffeeCoverageReportPath} #{buildPath}"
                        "$(DOMSCRAPER) #{featurePath} #{reportCopyPath} #{coffeeCoverageGlobalReportPath}"
                        "rm -rf #{coffeeCoveragePath}"
                        
                    ]
        )(testType, testFiles)


    # INSTANBUL Coverage

    # collect unit and integration tests
    coverageIntegration = []
    coverageUnit = []
    if manifest.integrationTests?.mocha?
        coverageIntegration = concatPaths manifest.integrationTests.mocha, {pre: coveragePath}
    if manifest.server?.tests?
        coverageUnit = concatPaths manifest.server.tests, {pre: coveragePath}

    testFilesForCoverage = _([coverageIntegration, coverageUnit]).flatten()

    # pre coverage
    rb.addToGlobalTarget "pre_coverage", rb.addRule "global-pre-coverage(instrument)", [], ->
        targets: coveragePath
        dependencies: featurePath
        actions: [
            "@mkdir -p #{coveragePath}"
            "@cp -r #{featurePath}/* #{coveragePath}"
            "$(COFFEEC) -c $(COFFEE_FLAGS) -o #{uninstrumentedPath} #{featurePath}"
            "$(ISTANBUL) instrument --no-compact -x \"**/test/**\" -x \"**/build/**\" -x \"**/_design/**\" -x \"**/components/**\" --output #{coveragePath} #{uninstrumentedPath}"
            "touch #{coveragePath}"
        ]


    if testFilesForCoverage.length > 0
        rb.addToGlobalTarget "feature_coverage", rb.addRule "global-coverage", [], ->
            targets: path.join featurePath, "coverage"
            dependencies: [
                "pre_coverage" # have to be the first dependency !
                concatPaths manifest.integrationTests?.mocha, {pre: featurePath}
                concatPaths manifest.server.tests, {pre: featurePath}
            ]
            actions: "-$(ISTANBUL_TEST_RUNNER) -p #{path.resolve lake.coveragePath} -o #{coverageReport} #{testFilesForCoverage.join ' '}"
