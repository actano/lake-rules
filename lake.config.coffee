path = require 'path'

root = process.cwd()

resolveManifest = (from, to) ->
    path.normalize path.join from, to, 'Manifest.coffee'

extendManifest = (manifest, featurePath) ->
    manifest.featurePath = featurePath
    manifest.resolveManifest = (feature = '.') ->
        resolveManifest @featurePath, feature

    manifest.getManifest = (feature) ->
        loadManifest @resolveManifest feature
    return manifest

loadManifest = (manifestPath) ->
    try
        manifest = require path.resolve manifestPath
    catch err
        console.error "Error loading Manifest for %s: %s", manifestPath, err.message
        throw err

    return extendManifest manifest, path.dirname manifestPath

module.exports =
    config:
        root: root
        lakeOutput: path.join root, 'build', 'lake'
        featureBuildDirectory: '$(LOCAL_COMPONENTS)'
        remoteComponentPath:'$(REMOTE_COMPONENTS)'
        runtimePath: '$(RUNTIME)'

    resolveManifest: (feature) ->
        resolveManifest '.', feature

    getManifest: (feature) ->
        loadManifest @resolveManifest feature

    extendManifest: extendManifest