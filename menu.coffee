# Std Library
path = require 'path'

# Rule dep
component = require('./component')

# Local dep
{addJadeHtmlRule} = require './helper/jade'
Rule = require './helper/rule'

exports.title = 'menu'
exports.readme =
    name: 'menu'
    path: path.join __dirname, 'menu.md'
exports.description = 'build html files for the webapp menu'
exports.addRules = (config, manifest) ->
    return if not manifest.menus?

    buildPath = path.join config.featureBuildDirectory, config.featurePath
    _makeArray = (value) -> [].concat(value or [])

    # adds rules to create a single HTML file for a menu entry
    _addJadeTarget = (menuName, menuItem, pagePath) ->
        childManifest = require path.resolve(path.join(config.projectRoot, menuItem.page, 'Manifest'))

        if not childManifest?.page?.index?.jade?
          throw new Error("Feature #{menuItem.page} does not specfify a page view")

        html = path.join buildPath, 'menu', menuName, path.resolve('.', pagePath), 'index.html'
        jade = path.join config.projectRoot, menuItem.page, childManifest.page.index.jade
        obj = page:
            path: pagePath
            name: childManifest.name
            url: "/pages/#{childManifest.name}"
            i18nTag: menuItem.i18nTag

        jadeDeps = _makeArray(childManifest?.page?.index?.dependencies).map (dep) ->
            path.normalize(path.join config.featurePath, dep)

        jadeBuildDeps = jadeDeps.map (dep) ->
            component.getTargets(path.join(config.featureBuildDirectory, dep), 'component')

        addJadeHtmlRule jade, html, obj, jadeBuildDeps, jadeDeps

        new Rule path.join config.featurePath, 'build'
            .prerequisite html
            .write()

    # create targets for each menu in the manifest
    _walkManifest path.join(config.projectRoot, config.featurePath), manifest, _addJadeTarget

module.exports.getTargets = (config, manifest, tag) ->
    if not manifest.webapp?.menu? and not manifest.webapp?.menu[tag]?
        throw new Error("Unknown menu #{tag}")

    # tag is a bit misused: it's the name of the menu entry

    menuManifestPath = path.join(config.projectRoot, config.featurePath, manifest.webapp.menu[tag], 'Manifest')
    menuManifest = require menuManifestPath
    menuFeaturePath = path.relative config.projectRoot, path.dirname(menuManifestPath)

    buildPath = path.join '$(LOCAL_COMPONENTS)', menuFeaturePath

    targets = []
    _walkManifest path.join(config.projectRoot, menuFeaturePath), menuManifest, (menuName, menuItem, pagePath) ->
        html = [path.join(buildPath, 'menu', menuName), path.join(path.resolve('.', pagePath), 'index.html')]
        targets.push html
    return targets

_walkManifest = (featurePath, manifest, cb) ->
    for name, filename of manifest.menus
        pageManifest = require path.resolve(path.join(featurePath, filename))
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
