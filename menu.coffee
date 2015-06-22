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

_makeArray = (value) -> [].concat(value or [])

# adds rules to create a single HTML file for a menu entry
_addJadeTarget = (config, buildPath, menuItem, pagePath) ->
    childManifest = config.getManifest menuItem.page

    if not childManifest?.page?.index?.jade?
        throw new Error("Feature #{menuItem.page} does not specfify a page view")

    html = path.join buildPath, path.resolve('.', pagePath), 'index.html'
    jade = path.join config.root, menuItem.page, childManifest.page.index.jade
    obj = page:
        path: pagePath
        name: childManifest.name
        url: "/pages/#{childManifest.name}"
        i18nTag: menuItem.i18nTag

    jadeDeps = _makeArray(childManifest?.page?.index?.dependencies).map (dep) ->
        path.normalize(path.join manifest.featurePath, dep)

    jadeBuildDeps = jadeDeps.map (dep) ->
        component.getTargets(path.join(config.featureBuildDirectory, dep), 'component')

    addJadeHtmlRule jade, html, obj, jadeBuildDeps, jadeDeps

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

module.exports.installMenu = (config, feature, dstMenu) ->
    menuManifestPath =  path.join(config.root, manifest.featurePath, feature, 'Manifest')
    menuFeaturePath = path.relative config.root, path.dirname(menuManifestPath)

    targets = []
    _walkManifest path.join(config.root, menuFeaturePath), menuManifest, (menuName, menuItem, pagePath) ->
        targets.push _addJadeTarget config, dstMenu, menuItem, pagePath
    return targets

exports.addRules = (config, manifest) ->
