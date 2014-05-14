# Std Library
path = require 'path'

# Rule dep
component = require('./component')

# Local dep
{addMkdirRule} = require '../helper/filesystem'
{addJadeHtmlRule} = require '../helper/jade'

exports.title = 'menu'
exports.readme =
    name: 'menu'
    path: path.join __dirname, 'menu.md'
exports.description = 'build html files for the webapp menu'
exports.addRules = (lake, featurePath, manifest, rb) ->
    return if not manifest.menus?

    buildPath = path.join lake.featureBuildDirectory, featurePath
    _makeArray = (value) -> [].concat(value or [])

    # adds rules to create a single HTML file for a menu entry
    _addJadeTarget = (menuName, menuItem, pagePath) ->
        menuFeaturePath = path.join menuItem.page
        childManifest = require path.resolve(path.join(manifest.projectRoot, menuFeaturePath, 'Manifest'))

        if not childManifest?.page?.index?.jade?
          throw new Error("Feature #{menuItem.page} does not specfify a page view")

        html = path.join buildPath, 'menu', menuName, path.resolve('.', pagePath), 'index.html'
        jade = path.resolve path.join menuFeaturePath, childManifest.page.index.jade
        obj = page:
            path: pagePath
            name: childManifest.name
            url: "/pages/#{childManifest.name}"
            i18nTag: menuItem.i18nTag

        jadeDeps = _makeArray(childManifest?.page?.index?.dependencies).map (dep) ->
            path.normalize(path.join featurePath, dep)

        jadeBuildDeps = jadeDeps.map (dep) ->
            component.getTargets(path.join(lake.featureBuildDirectory, dep), 'component')

        addJadeHtmlRule rb, jade, html, obj, jadeBuildDeps, (jadeDeps.map (dep) -> "--include #{dep}").join(' ')

        rb.addRule path.join(featurePath, 'build', html), [], ->
            targets: path.join featurePath, 'build'
            dependencies: html

    # create targets for each menu in the manifest
    _walkManifest manifest, _addJadeTarget

module.exports.getTargets = (manifest, tag) ->
    if not manifest.webapp?.menu? and not manifest.webapp?.menu[tag]?
        throw new Error("Unknown menu #{tag}")

    # tag is a bit misused: it's the name of the menu entry

    menuManifestPath = path.join(manifest.projectRoot, manifest.featurePath, manifest.webapp.menu[tag], 'Manifest')
    menuManifest = require menuManifestPath
    menuManifest.featurePath = path.relative manifest.projectRoot, path.dirname(menuManifestPath)

    buildPath = path.join '$(LOCAL_COMPONENTS)', menuManifest.featurePath

    targets = []
    _walkManifest menuManifest, (menuName, menuItem, pagePath) ->
        html = [path.join(buildPath, 'menu', menuName), path.join(path.resolve('.', pagePath), 'index.html')]
        targets.push html
    return targets

_walkManifest = (manifest, cb) ->
    for name, filename of manifest.menus
        pageManifest = require path.resolve(path.join(manifest.featurePath, filename))
        _walkMenuTree name, pageManifest.root, '', cb

_walkMenuTree = (menuName, menuItem, parentPath, cb) ->
    pagePath = parentPath + (menuItem.path ? '')
    if menuItem.page?
        cb(menuName, menuItem, pagePath)
    if menuItem.children?
        # N.B. paths in the menu structure already have a '/', so use + instead of path.join
        childPath = parentPath + menuItem.path
        for child in menuItem.children
            _walkMenuTree menuName, child, childPath, cb
