Rule = require './rule'
path = require 'path'

directoryCache = {}

addMkdirRule = (dir) ->
    if not directoryCache[dir]?
        directoryCache[dir] = true
        new Rule dir, 'mkdir'
            .action '@mkdir -p $@'
            .silent()
            .write()
    return dir

addMkdirRuleOfFile = (file) -> addMkdirRule path.dirname file

addCopyRule = (src, dst, options) ->
    rule = new Rule dst, 'copy'
        .silent()
        .prerequisite src
        .action '@cp -f $^ $@'
    rule.orderOnly addMkdirRuleOfFile dst unless options?.noMkdir
    rule.write()
    return dst

Rule::mkdir = ->
    for t in @_targets
        @orderOnly addMkdirRuleOfFile t
    this

module.exports.clearDirectoryCache = -> directoryCache = {}
module.exports.addMkdirRuleOfFile = addMkdirRuleOfFile
module.exports.addMkdirRule = addMkdirRule
module.exports.addCopyRule = addCopyRule

###
    replace the extension of a file (have to be dot seperated), ignoring the rest of the path (directories)
    last parameter needs to be in this format: '.html'
###
module.exports.replaceExtension = (sourcePath, newExtension) ->
    srcDir = path.dirname sourcePath
    baseName = path.basename sourcePath, path.extname sourcePath
    path.join srcDir, "#{baseName}#{newExtension}"
