# Std library
path = require 'path'

# Local dep
{
    resolveManifestVariables
    resolveFeatureRelativePaths
    replaceExtension
    concatPaths
    addMkdirRule
} = require "../rulebook_helper"

{componentBuildTarget} = require('./component')

exports.title = 'browser-tests'
exports.description =
    "browser tests: compile jade to html, use jquery and sinon"

exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    # These paths are all feature specific
    # lib/foobar/build
    buildPath = path.join lake.featureBuildDirectory, featurePath

    # project root relative paths
    projectRoot = path.resolve lake.lakePath, '..' # project root
    globalBuild = path.join projectRoot, 'build'

    if manifest.client?.tests?.browser?.html? and
            manifest.client?.tests?.browser?.scripts? and
            manifest.client.tests.browser.html isnt "" and
            manifest.client.tests.browser.scripts.length isnt 0

        manifestTest = manifest.client.tests.browser

        TEST_DIR = 'test'
        testHtmlPath = path.join buildPath, TEST_DIR
        testHtmlFile = path.join testHtmlPath, 'test.html'

        # compile the tests
        rb.addRule "browser-test-scripts", [], ->
            targets: concatPaths manifestTest.scripts, {}, (file) ->
                replaceExtension path.join(testHtmlPath, path.basename(file)), ".js"
            dependencies: concatPaths manifestTest.scripts, {pre: featurePath}
            actions: "$(COFFEEC) -c $(COFFEE_FLAGS) -o #{testHtmlPath} $^"

        # compile the test.jade
        testScripts = manifestTest.scripts.map (file) ->
            replaceExtension path.basename(file), '.js'

        componentBuild = componentBuildTarget(buildPath)
        relativeComponentDir = path.relative testHtmlPath, componentBuild.targetDst

        rb.addRule "test-jade", [], ->
            targets: testHtmlFile
            dependencies: [
                path.join featurePath, manifestTest.html
                rb.getRuleById("browser-test-scripts").targets
            ]
            actions: "$(JADEC) $< -P  --out #{testHtmlPath} " + \
                "--obj '#{JSON.stringify({name:manifest.name, tests: testScripts.join(' '), componentDir: relativeComponentDir})}'"

        # generate HTML markup for the global client test HTML overview
        rb.addToGlobalTarget "client_test_add", rb.addRule "client_test_add", [], ->
            targets: path.join featurePath, "client_test_add"
            dependencies: [
                rb.getRuleById("test-jade").targets
            ]
            actions: """echo "<iframe height='100%' width='100%' src='../#{testHtmlPath}'></iframe>" >> $(CLIENT_TEST_INDEX)"""

        prefix = lake.testReportPath
        reportPath = path.join prefix, featurePath

        addMkdirRule rb, reportPath

        # run the client test
        clientTestTarget = path.join featurePath, 'client_test'
        rb.addRule clientTestTarget, ["test"], ->
            targets: clientTestTarget
            dependencies: [
                componentBuild.target
                rb.getRuleById("test-jade").targets
                '|'
                reportPath
            ]
            actions: [
                # manifest.client.tests.browser.html is
                # 'test/test.jade' --convert to--> 'test.html'
                "PREFIX=#{prefix} REPORT_FILE=#{path.join featurePath, 'browser-test.xml'} $(CASPERJS) #{lake.browserTestWrapper} #{testHtmlFile}"
            ]

        rb.addRule 'client_test', [], ->
            targets: 'client_test'
            dependencies: clientTestTarget
