# Std library
path = require 'path'

# Third party
async = require 'async'

# Local dep
{concatPaths, replaceExtension} = require './rulebook_helper'

exports.title = 'documentation'
exports.description = 'build documentation with markdown'
exports.addRules = (lake, featurePath, manifest, ruleBook) ->

    _addDocuRule = (mdFile, callback) ->
        console.log "mdFile=#{mdFile}"
        htmlFile = replaceExtension mdFile, '.html'

        rb.addRule "documentation-#{mdFile}", [], ->
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

        callback()


    globalTargetName = 'documentation'
    rb = ruleBook

    # These paths are all feature specific
    # lib/foobar/build
    buildPath = path.join featurePath, lake.featureBuildDirectory
    # lib/fooabr/build/documentation
    documentationPath = path.join buildPath, 'documentation'

    # project root relative paths
    # build/runtime/lib/foobar
    localComponentPath = path.join lake.localComponentsPath, featurePath

    if manifest.documentation?
        # rule lib/adminpage/build/documentation: lib/adminpage/History.html lib/adminpage/Readme.html
        async.each manifest.documentation, _addDocuRule, (err) ->
            console.log err if err?


        # Rule to create file with commit comments
        commitMdFile = 'Commits.md'
        commitHtmlFile = 'Commits.html'
        rb.addRule "documentation-#{commitMdFile}", [], ->
            action = _getCommitAction(featurePath, documentationPath)

            rule =
                targets: path.join documentationPath, commitHtmlFile
                dependencies: ''
                actions: [
                    _getCommitAction(featurePath, documentationPath)
                ]
            return rule

        targetFiles =
            concatPaths manifest.documentation, {pre: documentationPath},
                (file) ->
                    replaceExtension file, '.html'
        targetFiles.push path.join documentationPath, commitHtmlFile

        rb.addToGlobalTarget globalTargetName,
            rb.addRule globalTargetName, [], ->
                targets: documentationPath
                dependencies: targetFiles
                actions: [
                    "touch #{documentationPath}"
                ]


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
    gitHubPath = 'https://github.com/global-communication/actano-rplan/commit/'
    format = "%n* %cd [%an] [%s](#{gitHubPath}%H)"
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

