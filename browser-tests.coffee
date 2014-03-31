# Std library
path = require 'path'

# Local dep
{
    resolveManifestVariables
    resolveFeatureRelativePaths
    replaceExtension
    concatPaths
} = require "./rulebook_helper"

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

        testHtmlPath = path.join buildPath, 'test'
        testHtmlFile = path.join testHtmlPath, path.basename(manifestTest.html)
        testHtmlFile = replaceExtension testHtmlFile, '.html'

        # copy jquery, sinon, rename them
        if manifestTest.assets?.scripts?
            rb.addRule "client-test-script-assets", ["test-assets"], ->
                resolvedFiles = resolveManifestVariables manifestTest.assets.scripts, projectRoot
                return {
                    targets: concatPaths manifestTest.assets.scripts, {}, (file) ->
                        if file.indexOf('sinon-1.7.3.js') > 0
                            path.join testHtmlPath, 'sinon.js'
                        else if file.indexOf('jquery-1.10.2.js') > 0
                            path.join testHtmlPath, 'jquery.js'
                        else
                            path.join testHtmlPath, path.basename(file)

                    dependencies: resolvedFiles
                    actions: concatPaths resolvedFiles, {}, (file) ->
                        if file.indexOf('sinon-1.7.3.js') > 0
                            "cp #{file} #{path.join(testHtmlPath, 'sinon.js')}"
                        else if file.indexOf('jquery-1.10.2.js') > 0
                            "cp #{file} #{path.join(testHtmlPath, 'jquery.js')}"
                        else
                            "cp #{file} #{path.join(testHtmlPath, path.basename(file))}"
                }

        # copy mocha styles
        if manifestTest.assets?.styles?
            rb.addRule "client-test-style-assets", ["test-assets"], ->
                resolvedFiles = resolveManifestVariables manifestTest.assets.styles, projectRoot
                return {
                    targets: concatPaths manifestTest.assets.styles, {}, (file) ->
                        path.join(testHtmlPath, path.basename(file))
                    dependencies: resolvedFiles
                    actions: concatPaths resolvedFiles, {}, (file) ->
                        "cp #{file} #{path.join(testHtmlPath, path.basename(file))}"
                }

        # compile the tests
        rb.addRule "browser-test-scripts", [], ->
            targets: concatPaths manifestTest.scripts, {}, (file) ->
                replaceExtension path.join(buildPath, file), ".js"
            dependencies: concatPaths manifestTest.scripts, {pre: featurePath}
            actions: "$(COFFEEC) -c $(COFFEE_FLAGS) -o #{buildPath} $^"

        # compile the test.jade
        testScripts = concatPaths manifestTest.scripts, {}, (file) ->
            replaceExtension file, '.js'

        console.log '## Feature ', featurePath                # lib/layout-2col
        console.log 'buildPath = ', buildPath                 # lib/layout-2col/build    -> build/local_components/lib/layout-2col
        console.log 'test html = ', manifestTest.html         # ../page/test/test.jade
        console.log 'testHtmlPath = ', testHtmlPath
        console.log 'testHtmlFile = ', testHtmlFile

        rb.addRule "test-jade", [], ->
            # use featurePath, to avoid test.html is located unter build/test.html
            # instead of build/test/test.html
            targets: testHtmlFile
#                                                             # file = lib/layout-2col/page/test/test.jade -> build/local_components/lib/page/test/test.jade
#                basename = path.basename file                # test.jade                                  -> test.jade
#                dirname = path.dirname path.dirname file     # lib/layout-2col/page                       -> build/local_components/lib/page
#                filePath = path.join dirname, basename       # lib/layout-2col/page/test.jade             -> build/local_components/lib/page/test.jade
#                replaceExtension filePath, '.html'           # lib/layout-2col/page/test.html             -> build/local_components/lib/page/test.html
            dependencies: [
                path.join featurePath, manifestTest.html
                rb.getRuleById("browser-test-scripts").targets
                resolveFeatureRelativePaths manifestTest.dependencies, projectRoot, featurePath
            ]
            actions: "$(JADEC) $< -P --obj {\\\"name\\\":\\\"#{manifest.name}\\\"\\\,\\\"tests\\\":\\\"#{testScripts.join '\\\ '}\\\"} --out #{testHtmlPath}"

        # generate HTML markup for the global client test HTML overview
        rb.addToGlobalTarget "client_test_add", rb.addRule "client_test_add", [], ->
            targets: path.join featurePath, "client_test_add"
            dependencies: [
                rb.getRuleById("feature").targets
                rb.getRuleById("test-jade").targets
                rule.targets for rule in rb.getRulesByTag("test-assets")
            ]
            actions: """echo "<iframe height='100%' width='100%' src='#{testHtmlPath}'></iframe>" >> $(CLIENT_TEST_INDEX)"""

        # run the client test
        rb.addToGlobalTarget "client_test", rb.addRule "client-test", ["test"], ->
            targets: path.join featurePath, "client_test"
            dependencies: [
                rb.getRuleById("feature").targets
                rb.getRuleById("test-jade").targets
                rule.targets for rule in rb.getRulesByTag("test-assets")
            ]
            actions: [
                # manifest.client.tests.browser.html is
                # 'test/test.jade' --convert to--> 'test.html'
                "$(MOCHAPHANTOMJS) --view 600x800 -R tap #{testHtmlFile}"
            ]
