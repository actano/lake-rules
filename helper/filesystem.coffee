Rule = require './rule'
path = require 'path'

directoryCache = {}

module.exports.clearDirectoryCache = ->
    for key of directoryCache
        delete directoryCache[key]

module.exports.addMkdirRuleOfFile = (addRule, file) ->
    addMkdirRule(addRule, path.dirname(file))

module.exports.addMkdirRule = addMkdirRule = (addRule, dir) ->
    if not directoryCache[dir]?
        directoryCache[dir] = true
        rule = new Rule dir
            .action '@mkdir -p $@'
            .silent()
        addRule rule
    return dir

module.exports.addCopyRule = (addRule, src, dst, options) ->
    dir = addMkdirRule(addRule, path.dirname dst) unless options?.noMkdir
    rule = new Rule dst
        .prerequisite src
        .action 'cp -f $^ $@'

    rule.orderOnly dir unless options?.noMkdir
    addRule rule
    return dst

###
    replace the extension of a file (have to be dot seperated), ignoring the rest of the path (directories)
    last parameter needs to be in this format: '.html'
###
module.exports.replaceExtension = (sourcePath, newExtension) ->
    path.join (path.dirname sourcePath), ((path.basename sourcePath, path.extname sourcePath) + newExtension)
