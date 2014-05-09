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

result = ""

class MyParser extends jade.Parser
    dependencies: {}

    addJade: (path) ->
        unless @dependencies[path]
            @dependencies[path] = true
            result += "-include #{dir}#{path}.includes\n"
        new nodes.Literal

    parseInclude: ->
        tok = @expect 'include'
        path = @resolvePath(tok.val.trim(), 'include')
        @addJade path

    parseExtends: ->
        tok = @expect 'extends'
        path = @resolvePath(tok.val.trim(), 'extends')
        @addJade path

options =
    filename: program.args[0]
    parser: MyParser

buf = fs.readFileSync options.filename

parser = new MyParser "#{buf}", options.filename, options

parser.parse()

result += "\n#{dir}#{options.filename}.dependencies:"
for key, value of parser.dependencies
    result += " #{key} #{dir}#{key}.dependencies"

result += "\n\ttouch \"$@\""

if program.out
    fs.writeFileSync program.out, result
else
    console.log result