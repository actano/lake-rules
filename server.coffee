# Std library
path = require 'path'

# Third party
glob = require 'glob'

# Local dep
{replaceExtension, concatPaths} = require "./rulebook_helper"

exports.title = 'server scripts, unit tests, resources'
exports.description = "do stuff for server"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    # These paths are all feature specific
    buildPath = path.join lake.featureBuildDirectory, featurePath # lib/foobar/build
    serverScriptDirectory = path.join buildPath, "server_scripts" # lib/foobar/build/

    if manifest.server?.scripts?.files?

        rb.addRule "run", [], ->
            targets: path.join featurePath, "run"
            dependencies: rb.getRuleById("feature").targets
            actions: "coffee #{path.join featurePath, 'server.coffee'}"

        for script in manifest.server.scripts.files
            ((script) ->
                scriptPath = path.join serverScriptDirectory, script
                scriptDirPath = path.dirname scriptPath
                rb.addRule "server-scripts-#{script}", ["feature", "server-script"], ->
                    targets: replaceExtension scriptPath, '.js'
                    dependencies: path.join featurePath, script
                    actions: [
                        "@mkdir -p #{serverScriptDirectory}"
                        "$(COFFEEC) -c $(COFFEE_FLAGS) --output #{scriptDirPath} $^"
                    ]
            )(script)

    if manifest.server?.scripts?.dirs?
        for dir in manifest.server.scripts?.dirs
            ((dir) ->
                scriptDirPath = path.join serverScriptDirectory, dir
                rb.addRule "server-scripts-dir-#{dir}", ["feature", "server-script"], ->
                    targets: scriptDirPath
                    dependencies: path.join featurePath, dir
                    actions: [
                        "@mkdir -p #{serverScriptDirectory}"
                        "$(COFFEEC) -c $(COFFEE_FLAGS) --output #{scriptDirPath} $^"
                    ]
            )(dir)

    if manifest.server?.tests?
        rb.addToGlobalTarget "unit_test", rb.addRule "unit-test", ["test"], ->
            targets: path.join featurePath, "unit_test"
            actions: concatPaths manifest.server.tests, {pre: featurePath},
                (testFile) ->
                    params = ''
                    if manifest.server.testParams?
                        for testParam in manifest.server.testParams
                            if testFile.indexOf(testParam.file) > -1
                                params += " #{testParam.param}"
                    "$(MOCHA)#{params} -R $(MOCHA_REPORTER) " +
                        "$(MOCHA_COMPILER) #{testFile}"

    # rule for copying resources to build directory
    if manifest.resources?.dirs?
        for dir in manifest.resources.dirs
            ((dir) ->
                resourcesPath = path.join featurePath, dir
                resourcesBuildPath = path.join buildPath, dir
                resourceFiles = glob.sync "*",
                    cwd: path.resolve resourcesPath
                    
                rb.addRule "resources-dir-#{dir}", ["feature", "resources"], ->
                    targets: concatPaths resourceFiles, { pre: resourcesBuildPath }
                    # a changed resource file is copied instantly by lake
                    # (without preceding lake clean)
                    dependencies: concatPaths resourceFiles, { pre: resourcesPath }
                    actions: [ 
                        "mkdir -p #{resourcesBuildPath}"
                        "cp -fr #{resourcesPath}/* #{resourcesBuildPath}/"
                    ]
            ) (dir)