path = require 'path'

{replaceExtension, addMkdirRuleOfFile} = require '../helper/filesystem'
{addPhonyRule} = require '../helper/phony'
{addCopyRule} = require '../helper/filesystem'

docpadSrc = 'build/htmldoc/src'
docpadOut = 'build/htmldoc/out'

gitHubPath = '$(GITHUB_URL)/commit/'
format = "%n* %cd [%an] [%s](#{gitHubPath}%H)"

component = require './component'

_ = require 'underscore'

exports.description = 'build HTML documentation'
exports.readme =
    name: 'htmldoc'
    path: path.join __dirname, 'htmldoc.md'
exports.addRules = (lake, featurePath, manifest, rb) ->
    _local = (target) -> path.join featurePath, target
    _out = (target) -> path.join docpadOut, target

    if manifest.name is 'htmldoc'
        buildPath = path.join lake.featureBuildDirectory, featurePath
        componentTarget = component.getTargets buildPath, 'component-build'

        # TODO: Remove strong knowledge of component output (htmldoc.js and htmldoc.css)
        htmldocTargets = _(['htmldoc.js', 'htmldoc.css']).map (filename) ->
            addCopyRule rb, path.join(componentTarget.targetDst, filename), _out(filename), noMkdir: true

        rb.addRule 'htmldoc', [], ->
            targets: 'htmldoc'
            dependencies: [componentTarget.target].concat htmldocTargets

    return unless manifest.documentation?.length > 0

    featureTarget = path.join docpadSrc, featurePath
    targets = []

    for mdFile in manifest.documentation
        do (mdFile) ->
            src = _local mdFile

            if mdFile.toLocaleLowerCase() is 'readme.md'
                target = path.join featureTarget, 'index.html.md'
            else
                target = path.join featureTarget, replaceExtension mdFile.toLocaleLowerCase(), ".html#{path.extname mdFile}"

            targetDir = addMkdirRuleOfFile rb, target

            rb.addRule target, [], ->
                targets: target
                dependencies: [src, '|', targetDir]
                actions: 'cat tools/htmldoc/header.md "$<" > "$@"'

            targets.push target

    commitTarget = path.join featureTarget, 'commit.html.md'
    targetDir = addMkdirRuleOfFile rb, commitTarget

    rb.addRule commitTarget, [], ->
        targets: commitTarget
        dependencies: ['|', targetDir]
        actions: [
            "@cat tools/htmldoc/header_commitlog.md > \"$@\""
            "@$(GIT) log --no-merges --name-only --pretty=\"#{format}\" \"#{featurePath}\" | sed 's/^\\([^\\*].*\\)/    - \\1/g' >> \"$@\""
        ]

    targets.push commitTarget

    rb.addRule 'build/htmldoc/out', [], ->
        targets: 'build/htmldoc/out'
        dependencies: targets
