# Std library
path = require 'path'
fs = require 'fs'

# Third party
async = require 'async'

# Local dep
{concatPaths, replaceExtension} = require './rulebook_helper'

docpadsrc = 'build/htmldoc/src'
gitHubPath = '$(GITHUB_URL)/commit/'
format = "%n* %cd [%an] [%s](#{gitHubPath}%H)"

exports.title = 'htmldoc'

exports.description = 'build htmldoc with docpad'

exports.addRules = (lake, featurePath, manifest, ruleBook) ->
    rb = ruleBook
    featureTarget = path.join docpadsrc, featurePath

    _addFeatureRule = ->
        rb.addToGlobalTarget 'build/htmldoc',
            rb.addRule "build/htmldoc/#{featurePath}", [], ->
                targets: "#{featurePath}/htmldoc"
                dependencies: [
                    rule.targets for rule in rb.getRulesByTag 'htmldoc'
                ]

    _addFileRule = (mdFile) ->
        src = path.join featurePath, mdFile
        if mdFile.toLocaleLowerCase() == 'readme.md'
            htmlFile = path.join featureTarget, 'index.html.md'
        else
            htmlFile = path.join featureTarget, replaceExtension mdFile.toLocaleLowerCase(), ".html#{ path.extname mdFile }"

        rb.addRule "#{htmlFile}", ['htmldoc'], ->
            rule =
                targets: htmlFile
                dependencies: src
                actions: [
                    '@mkdir -p "$(@D)"'
                    '@cat tools/htmldoc/header.md "$<" > "$@"'
                    "@mkdir -p #{docpadsrc}"
                    "@touch #{docpadsrc}"
                ]
            return rule

    _addCommitLog = ->
        htmlFile = path.join featureTarget, 'commits.html.md'
        rb.addRule "#{htmlFile}", ['htmldoc'], ->
            rule =
                targets: htmlFile
                actions: [
                    '@mkdir -p "$(@D)"'
                    "@cat tools/htmldoc/header_commitlog.md > \"$@\""
                    "@$(GIT) log --no-merges --name-only --pretty=\"#{format}\" \"#{featurePath}\" | sed 's/^\\([^\\*].*\\)/    - \\1/g' >> \"$@\""
                    "@mkdir -p #{docpadsrc}"
                    "@touch #{docpadsrc}"
                ]
            return rule
    if manifest.documentation? and manifest.documentation.length > 0
        for mdFile in manifest.documentation
            _addFileRule mdFile
        _addCommitLog()
        _addFeatureRule()
