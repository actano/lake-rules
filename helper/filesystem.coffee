path = require 'path'

directoryCache = {}

module.exports.addMkdirRuleOfFile = (ruleBook, file) ->
    addMkdirRule(ruleBook, path.dirname(file))

module.exports.addMkdirRule = addMkdirRule = (ruleBook, dir) ->
    if not directoryCache[dir]?
        directoryCache[dir] = true
        ruleBook.addRule dir, [], ->
            targets: dir
            actions: 'mkdir -p $@'
    return dir

module.exports.addCopyRule = (ruleBook, src, dst) ->
    dir = addMkdirRule(ruleBook, path.dirname dst)
    ruleBook.addRule dst, [], ->
        targets: dst
        dependencies: [src, '|', dir]
        actions: 'cp -f $^ $@'
    return dst

###
    replace the extension of a file (have to be dot seperated), ignoring the rest of the path (directories)
    last parameter needs to be in this format: '.html'
###
module.exports.replaceExtension = (sourcePath, newExtension) ->
    path.join (path.dirname sourcePath), ((path.basename sourcePath, path.extname sourcePath) + newExtension)
