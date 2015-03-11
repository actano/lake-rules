#!/usr/bin/env coffee
jade = require 'jade'

fs = require 'fs'
program = require 'commander'

includePaths = []

program
    .usage('[options] file')
    .option('-O, --obj <str>', 'javascript options object')
    .option('-p, --path <path>', 'filename used to resolve includes')
    .option('-i, --include [path]', 'add directory <path> to include paths', (val) -> includePaths.push val)
    .option('-P, --pretty', 'compile pretty html output')
    .option('-D, --no-debug', 'compile without debugging (smaller functions)')
    .option('-o, --out <file>', 'output the compiled js to <file>')
    .option('-c, --client', 'compile function for client-side runtime.js')
    .option('-d, --deny-parent', 'deny ../ lookup in extend/require')

program.parse process.argv

if program.args.length != 1
    console.log program.helpInformation()
    process.exit 1

class MyParser extends jade.Parser
    constructor: () ->
        jade.Parser.apply(@, arguments)

    resolvePath: (path, purpose) ->
        {basename,join,normalize} = require 'path'
        
        if options.denyParent && (normalize(path).indexOf('..') >= 0)
            throw "Denied resolving #{path} from #{options.filename}"

        if (basename(path).indexOf('.') == -1)
            path += '.jade'

        for p in @options.includePaths
            test = join p, path
            if fs.existsSync test
                return normalize test

        super path, purpose

class MyCompiler extends jade.Compiler
    constructor: () ->
        jade.Compiler.apply(@, arguments)

    visitTag: (tag) ->
        if tag.name == 'exports'
            throw "exports() no more allowed in jade"

        if tag.name == 'require'
            throw "require() no more allowed in jade"

        super tag

options = {}
data = {}

if program.obj
  if fs.existsSync(program.obj)
    data = JSON.parse fs.readFileSync program.obj
  else
    data = eval '(' + program.obj + ')'
  options = ->
  options.prototype = data
  options = new options()

options.client |= program.client
options.compileDebug |= program.debug
options.pretty |= program.pretty
options.filename = program.args[0]
options.compiler = MyCompiler
options.parser = MyParser
options.includePaths = includePaths
options.denyParent |= program.denyParent

compileJade = (filename) ->
    buf = fs.readFileSync options.filename = filename
    options.name = 'template'
    js = jade.compileClient buf, options
    return "module.exports = function(jade){ return #{js} }"

require.extensions['.jade'] = (client, filename) ->
    js = compileJade filename
    client._compile(js, filename)

result = null
if program.client
    result = compileJade options.filename
else
    path = require 'path'
    relativeName = path.relative __dirname, options.filename
    fn = require relativeName
    template = fn jade.runtime
    result = template data

if program.out
    fs.writeFileSync program.out, result
else
    console.log result