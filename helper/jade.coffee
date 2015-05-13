{command, prereq} = require './build-server'

path = require 'path'
fs = require './filesystem'
JADE = "$(COFFEE) #{path.join __dirname, 'jade-require.coffee'}"
{Command} = require 'commander'

makeDependencies = (src, dir, extraDependencies) ->
    result = [src]
    result = result.concat extraDependencies if extraDependencies?
    result.push '|' if result.indexOf('|') is -1
    result.push dir
    return result

parseExtraArguments = (extraArguments) ->
    includePaths = []
    if extraArguments?
        cmd = new Command()
            .usage('[options]')
            .option('-i, --include [path]', 'add directory <path> to include paths', (val) -> includePaths.push val)
        remaining = cmd.parseOptions extraArguments.split(' ')

        if remaining.length
            throw Error("Extra Arguments not supported: #{remaining.join ' '}")
    includePaths

module.exports.addJadeHtmlRule = (addRule, src, dst, object, extraDependencies, extraArguments) ->
    includePaths = parseExtraArguments extraArguments

    addRule
        targets: dst
        dependencies: prereq makeDependencies src, extraDependencies
        actions: command 'jade_html', null, null, JSON.stringify(object).replace(/\n/g, ' '), includePaths...
    return dst

module.exports.addJadeJavascriptRule = (addRule, src, dst, extraDependencies, extraArguments) ->
    includePaths = parseExtraArguments extraArguments

    addRule
        targets: dst
        dependencies: prereq makeDependencies src, extraDependencies
        actions: command 'jade_js', null, null, includePaths...
    return dst
