Promise = require 'bluebird'
path = require 'path'
fs = Promise.promisifyAll require 'fs'

Rule = require './helper/rule'

RESULT = path.join '$(BUILD)', 'htmldoc', 'index.html'

stopPaths = {}

PARTIALS = path.join path.join '$(BUILD)', 'htmldoc-partials'

mdRule = (src, title) ->
    new Rule path.join(PARTIALS, "#{src}.html"), 'htmldoc-md'
        .prerequisite src
        .buildServer 'htmldoc-markdown', null, null, title

done = Promise.coroutine ->

    stopNames = {}
    for v in ['tmp', 'cookbooks', 'build', 'node_modules', 'test_reports']
        stopNames[v] = true

    class Entry
        constructor: (@path) ->
        toString: -> @path

    class Directory extends Entry
        toRule: ->
            rule = new Rule path.join(PARTIALS, @path, 'index.html'), 'htmldoc-dir'
            if @readme
                rule.prerequisite @readme.path
            rule.buildServer 'htmldoc-index', null, @path, '$<'

    class Markdown extends Entry
        toRule: -> mdRule @path


    directories = {}
    results = []

    # Recursivly read all directories that are not excluded
    readDir = Promise.coroutine (dir) ->
        results.push directories[dir] = new Directory dir
        files = yield fs.readdirAsync dir
        Promise.all files.map Promise.coroutine (file) ->
            unless stopNames[file] or '.' is file.substring 0, 1
                file = path.join dir, file
                unless stopPaths[file]
                    stats = yield fs.statAsync file
                    if stats.isDirectory()
                        return readDir file

                    if path.extname(file).toLowerCase() is '.md'
                        entry = new Markdown file
                        if path.basename(file).toLowerCase() is 'readme.md'
                            directories[path.dirname file].readme = entry
                        else
                            results.push entry

    yield readDir '.'

    endInclude = yield Rule.startInclude 'htmldoc'
    nonFeatureRule = new Rule RESULT, 'htmldoc'
        .prerequisite '$(LAKE_DIR)htmldoc.jade'
        .buildServer 'htmldoc-result', null, '$^'
    for e in results
        rule = e.toRule()
        nonFeatureRule.prerequisite rule.write()
    nonFeatureRule.write()
    endInclude()

addRules = (manifest) ->
    stopPaths[manifest.featurePath] = true
    buildPath = path.join PARTIALS, manifest.featurePath
    featureRule = new Rule path.join(buildPath, 'index.html'), 'htmldoc-feature'
        .prerequisiteOf RESULT
        .buildServer 'htmldoc-feature'

    if manifest.documentation?
        for doc in manifest.documentation
            src = path.join manifest.featurePath, doc
            ext = path.extname doc
                .toLowerCase()
            if ext is '.md'
                title = if doc.toLowerCase() is 'readme.md' then manifest.featurePath else null
                md = mdRule src, title
                featureRule.prerequisite md.write()
            else if ext is '.js'
                featureRule.prerequisite src
            else
                throw new Error "Unsupported documentation file-type: #{doc}"




    featureRule.write()


module.exports = {
    done
    addRules
}
