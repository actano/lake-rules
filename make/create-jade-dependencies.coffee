#!/usr/bin/env coffee
jade = require 'jade'
nodes = require 'jade/lib/nodes'

fs = require 'fs'
program = require 'commander'

program.usage('[options] file')
    .option('-d, --dir <str>', 'makefile output prefix, e.g. \'${BUILD_DIR}/\'')
    .option('-o, --out <file>', 'output the Makefile to <file>')

program.parse process.argv

if program.args.length != 1
    console.log program.helpInformation()
    process.exit 1

dir = "#{program.dir}"

class MyParser extends jade.Parser
    dependencies: {}
    result: []

    addJade: (path) ->
        unless @dependencies[path]
            @dependencies[path] = true
            @result.push "-include #{dir}#{path}.includes"
        new nodes.Literal

    parseInclude: ->
        tok = @expect 'include'
        path = @resolvePath(tok.val.trim(), 'include')
        @addJade path

    parseExtends: ->
        tok = @expect 'extends'
        path = @resolvePath(tok.val.trim(), 'extends')
        @addJade path

    createMakefile: ->
        @result = []
        @parse()
        @result.push ""
        r = "\n#{dir}#{options.filename}.dependencies:"
        for key, value of parser.dependencies
            r += " #{key} #{dir}#{key}.dependencies"
        @result.push r
        @result.push "\ttouch \"$@\""
        @result.join '\n'

options =
    filename: program.args[0]
    parser: MyParser

buf = fs.readFileSync options.filename
parser = new MyParser "#{buf}", options.filename, options

result = parser.createMakefile()

if program.out
    fs.writeFileSync program.out, result
else
    console.log result