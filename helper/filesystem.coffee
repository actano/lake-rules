path = require 'path'

module.exports.addMkdirRuleOfFile = (ruleBook, file) ->
    addMkdirRule(ruleBook, path.dirname(file))

module.exports.addMkdirRule = addMkdirRule = (ruleBook, dir) ->
    ruleBook.directoryCache ?= {}
    if not ruleBook.directoryCache[dir]?
        ruleBook.directoryCache[dir] = {}
        ruleBook.addRule dir, [], ->
            targets: dir
            actions: 'mkdir -p $@'
    return dir

module.exports.addCopyRule = (ruleBook, src, dst, options) ->
    dir = addMkdirRule(ruleBook, path.dirname dst) unless options?.noMkdir
    ruleBook.addRule dst, [], ->
        targets: dst
        dependencies: if options?.noMkdir then [src] else [src, '|', dir]
        actions: 'cp -f $^ $@'
    return dst

###
    replace the extension of a file (have to be dot seperated), ignoring the rest of the path (directories)
    last parameter needs to be in this format: '.html'
###
module.exports.replaceExtension = (sourcePath, newExtension) ->
    path.join (path.dirname sourcePath), ((path.basename sourcePath, path.extname sourcePath) + newExtension)
