# Std library
path = require 'path'

# Local dep
{replaceExtension, addMkdirRuleOfFile} = require '../helper/filesystem'
{addPhonyRule} = require '../helper/phony'
{addCopyRule} = require '../helper/filesystem'

# Rule dep
componentBuild = require './component-build'

htmldoc = '$(HTMLDOC)'
docpadSrc = "#{htmldoc}/src"
docpadOut = "#{htmldoc}/out"

gitHubPath = '$(GITHUB_URL)/commit/'
format = "%n* %cd [%an] [%s](#{gitHubPath}%H)"

exports.description = 'build HTML documentation'
exports.readme =
    name: 'htmldoc'
    path: path.join __dirname, 'htmldoc.md'
exports.addRules = (config, manifest, rb) ->
    _local = (target) -> path.join config.featurePath, target
    _out = (target) -> path.join docpadOut, target

    if manifest.name is 'htmldoc'
        buildPath = path.join config.featureBuildDirectory, config.featurePath
        componentTarget = componentBuild.getTargets buildPath, 'component-build'

        # TODO: Remove strong knowledge of component output (htmldoc.js and htmldoc.css)
        htmldocTargets = []
        for filename in ['htmldoc.js', 'htmldoc.css']
            htmldocTargets.push addCopyRule rb, path.join(componentTarget.targetDst, filename), _out(filename), noMkdir: true

        rb.addRule
            targets: 'htmldoc'
            dependencies: [componentTarget.target].concat htmldocTargets

    return unless manifest.documentation?.length > 0

    featureTarget = path.join docpadSrc, config.featurePath
    targets = []

    for mdFile in manifest.documentation
        do (mdFile) ->
            src = _local mdFile

            if mdFile.toLocaleLowerCase() is 'readme.md'
                target = path.join featureTarget, 'index.html.md'
            else
                target = path.join featureTarget, replaceExtension mdFile.toLocaleLowerCase(), ".html#{path.extname mdFile}"

            targetDir = addMkdirRuleOfFile rb, target

            rb.addRule
                targets: target
                dependencies: [src, '|', targetDir]
                actions: 'cat tools/htmldoc/header.md "$<" > "$@"'

            targets.push target

    commitTarget = path.join featureTarget, 'commit.html.md'
    targetDir = addMkdirRuleOfFile rb, commitTarget

    rb.addRule
        targets: commitTarget
        dependencies: ['|', targetDir]
        actions: [
            "@cat tools/htmldoc/header_commitlog.md > \"$@\""
            "@$(GIT) log --no-merges --name-only --pretty=\"#{format}\" \"#{config.featurePath}\" | sed 's/^\\([^\\*].*\\)/    - \\1/g' >> \"$@\""
        ]

    targets.push commitTarget

    rb.addRule
        targets: "#{htmldoc}/out"
        dependencies: targets
