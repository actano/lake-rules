# Std library
path = require 'path'

# Local dep
{replaceExtension} = require "./rulebook_helper"

exports.title = 'translations'
exports.description = "compile translation phrases from coffee to js"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    # These paths are all feature specific
    # lib/foobar/build
    buildPath = path.join lake.featureBuildDirectory, featurePath

    if manifest.client?.translations?

        for languageCode, script of manifest.client.translations
            ((languageCode, script) ->
                targetPath = path.join buildPath, 'translations', path.basename script
                targetDir = path.dirname targetPath
                rb.addRule "translation-#{languageCode}", ["client", 'component-build-prerequisite', 'add-to-component-scripts'], ->
                    targets: replaceExtension targetPath, '.js'
                    dependencies: path.join featurePath, script
                    actions: [
                        "mkdir -p #{targetDir}"
                        "$(COFFEEC) -c $(COFFEE_FLAGS) --stdio <$^ >#{targetDir}/#{languageCode}.js"
                    ]
                    
            )(languageCode, script)

        target = path.join buildPath, 'translations/index.js'
        langArray = JSON.stringify(key for key of manifest.client.translations)
        rb.addRule 'translation index', ["client", 'component-build-prerequisite', 'add-to-component-scripts'], ->
            targets: target
            dependencies: []
            actions: [
                "mkdir -p #{path.dirname target}"
                "$(COFFEEC) -e 'console.log require(\"#{replaceExtension module.filename, '.coffee'}\").template(#{langArray})' > $@"
            ]

## This is the template function used by the translations index build step above
module.exports.template = (languageCodes) ->
    
    f = ->
        ## This is what ends up in translations/index.js
        module.exports.availableLanguages = -> XXX
        module.exports.getPhrases = (languageCode) -> require "./#{languageCode}"
        return
    
    entire = f.toString().replace /XXX/, JSON.stringify languageCodes
    body = entire.substring entire.indexOf("{") + 1, entire.lastIndexOf("}")
    return body
