# Std library
path = require 'path'

# Local dep
{replaceExtension} = require "./rulebook_helper"

exports.title = 'client-scripts'
exports.description = "compile client scripts"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    # These paths are all feature specific
    # lib/foobar/build
    buildPath = path.join featurePath, lake.featureBuildDirectory 

    if manifest.client?.scripts?

        for script in manifest.client.scripts
            ((script) ->
                scriptPath = path.join buildPath, script
                scriptDirPath = path.dirname scriptPath
                rb.addRule "client-#{script}", ["coffee-client", "client"], ->
                    targets: replaceExtension scriptPath, '.js'
                    dependencies: path.join featurePath, script
                    actions: "$(COFFEEC) -c $(COFFEE_FLAGS) -o #{scriptDirPath} $^"
            )(script)
