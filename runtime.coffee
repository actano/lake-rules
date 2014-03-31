# Std library
path = require 'path'
fs = require 'fs'

# Third party
{_} = require 'underscore'

exports.title = 'runtime'
exports.description = "install/copy runtime files for webapp"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    # These paths are all feature specific
    buildPath = path.join lake.featureBuildDirectory, featurePath # lib/foobar/build
    componentBuildDirectory = "component-build" # lib/foobar/build/component-build
    serverScriptDirectory = path.join buildPath, "server_scripts" # lib/foobar/build/

    # project root relative paths
    projectRoot = path.resolve lake.lakePath, ".." # project root
    featureRuntimePath = path.join lake.runtimePath, featurePath # build/runtime/lib/foobar

    # RUNTIME TARGET #

    ###
        component.json
        servers script files
        build
            htdocs.html files
            featureName.js
            featureName.css
            other-dir
    ###

    # pseudo rule, is used by install rule via getRulesByTag()
    if manifest.client?.views?.files?
        for viewFile in manifest.client.views.files
            do (viewFile) ->
                rb.addRule "runtime-view-#{viewFile}", ["runtime-view"], ->
                    targets: ""
                    dependencies: path.join featurePath, viewFile

    # pseudo rule, is used by install rule via getRulesByTag()
    if manifest.client?.views?.dirs?
        for viewDir in manifest.client.views.dirs
            viewFiles = fs.readdirSync(path.join projectRoot, featurePath, viewDir)
            for viewFile in viewFiles
                do (viewFile, viewDir) ->
                    fileName = path.basename viewFile
                    filePath = path.join featurePath, viewDir, viewFile
                    rb.addRule "runtime-view-dir-#{viewFile}", ["runtime-view"], ->
                        targets: ""
                        dependencies: filePath

    rb.addToGlobalTarget "install-features", rb.addRule "runtime", [], ->

        copyActions = []
        copyActions.push "mkdir -p #{featureRuntimePath}"
        copyActions.push "mkdir -p #{path.join featureRuntimePath, 'build'}"
        copyActions.push "mkdir -p #{path.join featureRuntimePath, 'views'}"

        htdocs = (rule.targets for rule in rb.getRulesByTag('htdocs'))

        for doc in htdocs
            dirname = path.dirname doc
            dirname = dirname.replace /build\/local_components\//, ''
            copyActions.push "cp -fp #{doc} #{path.join lake.runtimePath, dirname}/"

        runtimeViews = (rule.dependencies for rule in rb.getRulesByTag('runtime-view'))
        for view in runtimeViews
            dirname = path.dirname view
            copyActions.push "cp -fp #{view} #{path.join lake.runtimePath, dirname}/"

#        if rb.getRulesByTag("server-script").length > 0
#            copyActions.push "cp -frp #{serverScriptDirectory}/* #{featureRuntimePath}"

        if rb.getRuleById("component-build")?
            componentBuildTargets = rb.getRuleById("component-build").targets
            if _([componentBuildTargets]).flatten().join(' ').trim() isnt ""
                copyActions.push "cp -frp #{path.join buildPath, componentBuildDirectory}/* #{featureRuntimePath}/build"

        clientScripts = (rule.targets for rule in rb.getRulesByTag("coffee-client"))

        componentJson = rb.getRuleById('component.json', {}).targets
        if componentJson?
            copyActions.push "cp -fp #{componentJson} #{featureRuntimePath}"

        if manifest.resources?.dirs? or manifest.database?.designDocuments?
            for rule in rb.getRulesByTag 'resources', true
                for resourceFile, i in rule.dependencies
                    resourceFileRuntimePath = path.join lake.runtimePath,
                        resourceFile
                    if i is 0
                        copyActions.push "mkdir -p " +
                            "#{path.dirname resourceFileRuntimePath}"
                    copyActions.push "cp -fp #{resourceFile} " +
                        "#{resourceFileRuntimePath}"

        # additional action for stripping down manifest files for runtime
        stripAction = "$(COFFEEC) #{projectRoot}/tools/strip_manifest.coffee " +
            "-s #{featurePath}/Manifest.coffee -t #{featureRuntimePath}/Manifest.json"

        installFile = path.join lake.runtimePath, featurePath, 'install'
        # return this object
        targets: installFile
        dependencies: (rule.targets for rule in rb.getRulesByTag("feature"))
        actions: [
            _(copyActions).flatten()
            stripAction
            "mkdir -p #{path.join lake.runtimePath, featurePath}"
            "touch #{installFile}"
        ]

    # alias for build/runtime/lib/feature/install
    # alias is: lib/feature/install (old style) 
    rb.addRule "runtime-alias", [], ->
        targets: path.join featurePath, 'install'
        dependencies: rb.getRuleById("runtime").targets