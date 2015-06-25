path = require 'path'

root = process.cwd()

resolveManifest = (from, to) ->
    path.normalize path.join from, to, 'Manifest.coffee'

extendManifest = (manifest, featurePath) ->
    throw new Error "no featurepath given" unless featurePath?
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

defaultConfig =
    config:
        root: root
        lakeOutput: path.join 'build', 'lake'
        featureBuildDirectory: '$(LOCAL_COMPONENTS)'
        remoteComponentPath:'$(REMOTE_COMPONENTS)'
        runtimePath: '$(RUNTIME)'
        clientPath: '$(CLIENT)'
    features: []
    rules: []

loadConfig = ->
    try
        require 'coffee-script/register'

    p = path.resolve 'lake.config'
    try
        configurator = require p
    catch e
        console.error 'WARN: cannot require %s: %s', p, e

    configurator defaultConfig if configurator?
    return defaultConfig

module.exports = loadConfig()
module.exports.resolveManifest = (feature) ->
    resolveManifest '.', feature
module.exports.getManifest = (feature) ->
    loadManifest resolveManifest '.', feature
module.exports.extendManifest = extendManifest