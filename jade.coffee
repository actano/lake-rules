# Std library
path = require 'path'

# Local dep
{
    resolveFeatureRelativePaths
    replaceExtension
    addPhonyRule
} = require "./rulebook_helper"

exports.title = 'jade'
exports.description = "compile jade to js and to HTML"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    # These paths are all feature specific
    buildPath = path.join lake.featureBuildDirectory, featurePath # lib/foobar/build

    # project root relative paths
    projectRoot = path.resolve lake.lakePath, ".." # project root

    # TODO this belongs to component rules
    if manifest.client?.templates?
        if manifest.client?.mixins?.require
            options = "--obj '#{JSON.stringify(mixins: options)}'"
        else
            options = ""

        for jadeTemplate in manifest.client.templates
            do (jadeTemplate) ->
                rb.addRule "jade.template.#{jadeTemplate}", ["client", "jade-partials", 'component-build-prerequisite'], ->
                    targets: path.join buildPath, replaceExtension(jadeTemplate, '.js')
                    dependencies: path.join featurePath, jadeTemplate
                    actions: [
                        "@mkdir -p $(@D)"
                        "$(JADEREQUIRE) #{options} --out \"$@\" \"$<\""
                    ]

    if manifest.htdocs?
        htDocTargets = []
        for key, htDocItem of manifest.htdocs
            continue if not htDocItem.html?
            target =  path.join buildPath, key, path.basename(replaceExtension(htDocItem.html, '.html'))
            htDocTargets.push target
            do (key, htDocItem) ->
                rb.addRule "htdocs.#{key}", ["htdocs", "client", "feature"], ->
                    targets: target
                    # NOTE: path for foreign feature dependencies is relative, need to resolve it by build the absolute before
                    dependencies: [
                        path.join featurePath, htDocItem.html
                        resolveFeatureRelativePaths htDocItem.dependencies.templates, projectRoot, featurePath
                    ]
                    actions: "$(JADEC) $< --pretty  --out #{buildPath}/#{key}"

            rb.addRule "#{featurePath}/htdocs", [], ->
                targets: "#{featurePath}/htdocs"
                dependencies: htDocTargets
            addPhonyRule ruleBook, "#{featurePath}/htdocs"

            rb.addRule "htdocs", [], ->
                targets: "#{featurePath}/htdocs"
                dependencies: htDocTargets
            addPhonyRule ruleBook, "htdocs"
