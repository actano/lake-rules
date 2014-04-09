# Std library
path = require 'path'

exports.title = 'deploy'
exports.description = "deploy runtime files for webapp"

exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    projectRoot = path.resolve lake.lakePath, ".." # project root
    featureBuildPath = path.join lake.featureBuildDirectory, featurePath # build/local_components/lib/foobar
    featureRuntimePath = path.join lake.runtimePath, featurePath # build/runtime/lib/foobar
    deployTargets = []

    _addCopyRule = (file) ->
        dest = path.join(featureRuntimePath, file)
        src = path.join(featureBuildPath, file)
        deployTargets.push(dest)
        ruleBook.addRule "runtime-#{manifest.name}-#{file}", [], ->
            targets: dest
            dependencies: src
            actions: [
                "@mkdir -p #{featureRuntimePath}"
                "cp #{src} #{dest}"
            ]


    if manifest.page
        if manifest.client?.scripts?.length > 0
            _addCopyRule(manifest.name + ".js")


        if manifest.client?.styles?.length > 0
             _addCopyRule(manifest.name + ".css")

#    if manifest.server?.scripts?.files?.length > 0
#        console.log "manifest.server?.scripts #{manifest.name}"
#        for file in manifest.server.scripts.files
#            _addCopyRule(file.replace(".coffee", ".js"))

    # htdocs are missing
    # couchbase views are missing

    if deployTargets.length > 0
        manifestFilePath = "#{featurePath}/Manifest.coffee"
        manifestJSONFilePath = "#{featureBuildPath}/Manifest.json"

        ruleBook.addRule "runtime-#{manifest.name}-Manifest.coffee", [], ->
            targets: manifestJSONFilePath
            dependencies: manifestFilePath
            actions: [
                "$(COFFEEC) #{projectRoot}/tools/strip_manifest.coffee -s $< -t $@"
            ]

        _addCopyRule("Manifest.json")

        ruleBook.addRule "runtime-#{manifest.name}", [], ->
            targets: "install-features"
            dependencies: deployTargets
            actions: []
