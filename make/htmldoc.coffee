path = require 'path'

{replaceExtension, addMkdirRuleOfFile} = require '../helper/filesystem'
{addPhonyRule} = require '../helper/phony'

docpadSrc = 'build/htmldoc/src'
docpadOut = 'build/htmldoc/out'

gitHubPath = '$(GITHUB_URL)/commit/'
format = "%n* %cd [%an] [%s](#{gitHubPath}%H)"

exports.description = 'build HTML documentation'
exports.addRules = (lake, featurePath, manifest, rb) ->
    return unless manifest.documentation?.length > 0

    _local = (target) -> path.join featurePath, target

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
