path = require 'path'
{
    addMkdirRule
} = require '../rulebook_helper'

exports.description = ''
exports.addRules = (lake, featurePath, manifest, rb) ->
    return if not manifest.menus?

    buildPath = path.join lake.featureBuildDirectory, featurePath

    _addJadeTarget = (menuName, page, pagePath) ->
        return if not page.manifest?

        childManifest = require path.resolve(path.join(featurePath, page.manifest, 'Manifest'))
        return if not childManifest?.page?.index?.jade?

        html = path.join buildPath, 'menu', menuName, path.resolve('.', pagePath), 'index.html'
        jade = path.join featurePath, '..', name, childManifest.page.index.jade

        htmlDir = addMkdirRule rb, path.dirname html

        rb.addRule html, '[]', ->
            targets: html
            dependencies: [jade, '|', htmlDir]
            actions: "$(JADEC) $^ --pretty --out $(@D) --obj '{page: {path: \"#{pagePath}\", name: \"#{childManifest.name}\"}}'"

        rb.addRule path.join(featurePath, 'build', html), [], ->
            targets: path.join featurePath, 'build'
            dependencies: html

    # walks through the menu structure and calls _addJadeTarget
    _createTargetForPage = (menuName, page, parentPath) ->
        pagePath = parentPath + (page.path ? '')
        _addJadeTarget(menuName, page, pagePath)
        if page.pages?
            # TODO remove '/' from menu structure and use path.join instead of string concat
            childPath = parentPath + page.path
            for child in page.pages
                _createTargetForPage menuName, child, childPath

    # create targets for each menu in the manifest
    for name, filename of manifest.menus
        pageManifest = require path.resolve(path.join(featurePath, filename))
        _createTargetForPage name, pageManifest.root, ''
