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

exports.title = 'documentation'

exports.description = 'build documentation with markdown'

exports.addRules = (lake, featurePath, manifest, ruleBook) ->
# TODO drop me
    _addGlobalDocuTargetRule = ->
        rb.addToGlobalTarget globalTargetName,
            rb.addRule globalTargetName, [], ->
                targets: documentationPath
                dependencies: [
                    rule.targets for rule in rb.getRulesByTag 'documentation'
                ]
                actions: "touch #{documentationPath}"

    ###
        Create rules for Readme and History documentation
    ###
    _addDocuRules = (mdFile) ->
        htmlFile = replaceExtension mdFile, '.html'

        rb.addRule "documentation-#{mdFile}", ['documentation'], ->
            rule =
                targets: path.join documentationPath, htmlFile
                dependencies: concatPaths [mdFile], {pre: featurePath}
                actions: [
                    "@mkdir -p #{documentationPath}"
                    concatPaths [mdFile], {}, (mdFile) ->
                        "markdown #{path.join featurePath, mdFile} > " +
                        "#{path.join documentationPath, htmlFile}"
                    "touch #{documentationPath}"
                ]
            return rule
# TODO end drop me

    _addFeatureRule = ->
        rb.addToGlobalTarget 'build/htmldoc',
            rb.addRule "#{featurePath}/htmldoc", [], ->
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

        rb.addRule "htmldoc/#{src}", ['htmldoc'], ->
            rule =
                targets: htmlFile
                dependencies: src
                actions: [
                    "@mkdir -p #{path.dirname htmlFile}"
                    "@cat tools/htmldoc/header.md #{src} > #{htmlFile}"
                    "@mkdir -p #{docpadsrc}"
                    "@touch #{docpadsrc}"
                ]
            return rule

    _addCommitLog = ->
        htmlFile = path.join featureTarget, 'commits.html.md'
        rb.addRule "htmldoc/commits.html.md", ['htmldoc'], ->
            rule =
                targets: htmlFile
                actions: [
                    "@cat tools/htmldoc/header_commitlog.md > \"#{htmlFile}\""
                    "@$(GIT) log --no-merges --name-only --pretty=\"#{format}\" \"#{featurePath}\" | sed 's/^\\([^\\*].*\\)/    - \\1/g' >> \"#{htmlFile}\""
                    "@mkdir -p #{docpadsrc}"
                    "@touch #{docpadsrc}"
                ]
            return rule

    ###
        Creates rule for file containing the features commit comments.
    ###
    _addCommitRule = ->
        mdFile = "#{commitFileBasename}.md"
        htmlFile = "#{commitFileBasename}.html"
        rb.addRule "documentation-#{mdFile}", ['documentation'], ->
            action = _getCommitAction(featurePath, documentationPath)

            rule =
                targets: path.join documentationPath, htmlFile
                dependencies: ''
                actions: [
                    _getCommitAction(featurePath, documentationPath)
                ]
            return rule

    ###
        Creates the rule to create an html file containing the commits
        of a feature.

        Example command for feature working-set:
        git log --no-merges  --name-only
        --pretty="%n* %cd [%an] [%s]
        (https://github.com/global-communication/actano-rplan/commit/%H)"
        lib/working-set/ | sed 's/^\([^\*].*\)/    - \1/g'
        > CommitComments.md && markdown CommitComments.md
        > CommitComments.html && open CommitComments.html
    ###
    _getCommitAction = (featurePath, documentationPath) ->
        sedCommand = "| sed 's/^\\([^\\*].*\\)/    - \\1/g'"
        mdFile = 'Commits.md'
        htmlFile = 'Commits.html'
        deleteMdFileCommand = "rm #{documentationPath}/#{mdFile}"

        action = "git log " +
            "--no-merges " +
            "--name-only " +
            "--pretty=\"#{format}\" " +
            "#{featurePath} " +
            sedCommand +
            " > #{path.join documentationPath, mdFile} " +
            " && markdown #{path.join documentationPath, mdFile}" +
            " > #{path.join documentationPath, htmlFile} " +
            " && #{deleteMdFileCommand}"

        return action





    globalTargetName = 'documentation'
    commitFileBasename = 'Commit'
    rb = ruleBook

    # These paths are all feature specific
    # lib/foobar/build
    buildPath = path.join featurePath, lake.featureBuildDirectory
    # lib/foobar/build/documentation
    documentationPath = path.join buildPath, 'documentation'

    featureTarget = path.join docpadsrc, featurePath


    if manifest.documentation? and manifest.documentation.length > 0
        for mdFile in manifest.documentation
            _addDocuRules mdFile
            _addFileRule mdFile

        _addCommitLog()

        # Create file with commit comments only for features having
        # a readme.md file.
        docuString = manifest.documentation.join()
        if docuString.match(/readme\.md/i)?
            _addCommitRule()

        _addGlobalDocuTargetRule()
        _addFeatureRule()
