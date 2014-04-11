# Std library
path = require 'path'

# Local dep
{
    resolveFeatureRelativePaths
    replaceExtension
    lookup
} = require "./rulebook_helper"

exports.title = 'jade'
exports.description = "compile jade to js and to HTML"
exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook

    # These paths are all feature specific
    buildPath = path.join lake.featureBuildDirectory, featurePath # lib/foobar/build

    # project root relative paths
    projectRoot = path.resolve lake.lakePath, ".." # project root

    if manifest.client?.templates?
        options = manifest.client?.mixins?.require
        if options
            options = "--obj '#{JSON.stringify(mixins: options)}'"
        else
            options = ""

        for jadeTemplate in manifest.client.templates
            ((jadeTemplate) ->
                rb.addRule "jade.template.#{jadeTemplate}", ["client", "jade-partials", 'component-build-prerequisite'], ->
                    targets: path.join buildPath, replaceExtension(jadeTemplate, '.js')
                    dependencies: path.join featurePath, jadeTemplate
                    actions: [
                        "@mkdir -p $(@D)"
                        "$(JADEREQUIRE) #{options} --out \"$@\" \"$<\""
                    ]
            )(jadeTemplate)

    if manifest.htdocs?
        console.log manifest.name
        for key, value of manifest.htdocs
            ((key) ->
                rb.addRule "htdocs.#{key}", ["htdocs", "client", "feature"], ->
                    targets: path.join buildPath, path.basename(replaceExtension((lookup manifest, "htdocs.#{key}.html"), '.html'))
                    # NOTE: path for foreign feature dependencies is relative, need to resolve it by build the absolute before
                    dependencies: [
                        path.join(featurePath, lookup(manifest, "htdocs.#{key}.html"))
                        resolveFeatureRelativePaths lookup(manifest, "htdocs.#{key}.dependencies.templates"), projectRoot, featurePath
                    ]
                    actions: "$(JADEC) $< --pretty  --out #{buildPath}"
            )(key)
