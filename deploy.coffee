# Std library
path = require 'path'

exports.title = 'deploy'
exports.description = "deploy runtime files for webapp"

exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    projectRoot = path.resolve lake.lakePath, ".." # project root
    featureBuildPath = path.join lake.featureBuildDirectory, featurePath # build/local_components/lib/foobar
    featureRuntimePath = path.join lake.runtimePath, featurePath # build/runtime/lib/foobar
    deployTargets = []

    _addFeatureCopyRule = (file) ->
        _addCopyRule(featurePath, featureRuntimePath, file)

    _addBuildCopyRule = (file) ->
        _addCopyRule(featureBuildPath, featureRuntimePath, file)

    _addCopyRule = (src, dest, file) ->
        _src = path.join(src, file)
        _dest = path.join(dest, file)
        deployTargets.push(_dest)
        ruleId = "runtime:#{_dest}"
        ruleBook.addRule ruleId, [], ->
            targets: _dest
            dependencies: _src
            actions: [
                "@mkdir -p #{path.dirname(_dest)}"
                "cp #{_src} #{_dest}"
            ]

    if manifest.page
        # the following rule belongs to build page not to deploy page
        manifestFilePath = "#{featurePath}/Manifest.coffee"
        manifestJSONFilePath = "#{featureBuildPath}/Manifest.json"
        ruleBook.addRule "runtime:#{featurePath}/Manifest.coffee", [], ->
            targets: manifestJSONFilePath
            dependencies: manifestFilePath
            actions: [
                "$(COFFEEC) #{projectRoot}/tools/strip_manifest.coffee -s $< -t $@"
            ]
        deployTargets.push(manifestJSONFilePath)

        if manifest.page.index?.jade?
            _addFeatureCopyRule(manifest.page.index.jade)
            deps = manifest.page.index.dependencies || []
            _addFeatureCopyRule(dep) for dep in deps

        _addBuildCopyRule("Manifest.json")

        if manifest.client?.scripts?.length > 0
            destPath = path.join(featureRuntimePath, 'build')
            _addCopyRule(featureBuildPath, destPath, manifest.name + ".js")
            _addCopyRule(featureBuildPath, destPath, manifest.name + ".css")

    if manifest.server?.scripts?.files?.length > 0
        for file in manifest.server.scripts.files
            f = file.replace(".coffee", ".js")
            _addCopyRule(path.join(featureBuildPath, 'server_scripts'), featureRuntimePath, f )

    # htdocs are missing
    # couchbase views are missing

    if deployTargets.length > 0
        ruleBook.addToGlobalTarget "install-features", ruleBook.addRule "runtime:#{featurePath}", [], ->
            targets: path.join(featurePath, 'install')
            dependencies: deployTargets
            actions: []
