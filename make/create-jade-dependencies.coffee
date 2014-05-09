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
done = {}
todo = []

class MyParser extends jade.Parser
    constructor: (filename) ->
        buf = fs.readFileSync filename
        super "#{buf}", filename, {filename: filename}
        @dependencies = {}

    addJade: (path) ->
        unless @dependencies[path]
            @dependencies[path] = true
            @result.push "-include #{dir}#{path}.includes"

        todo.push path
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
        r = "\n#{dir}#{@filename}.dependencies:"
        for key, value of @dependencies
            r += " #{key} #{dir}#{key}.dependencies"
        @result.push r
        @result.push "\ttouch \"$@\"\n"
        @result.join '\n'

todo.push program.args[0]
while todo.length > 0
    path = todo.shift()
    unless done[path]
        done[path] = true

        target = "#{program.out}/#{path}.includes"
        srcStat = fs.statSync path
        fs.stat target, (err, targetStat) ->
            if srcStat.mtime.getTime() > targetStat?.mtime.getTime()
                parser = new MyParser path
                result = parser.createMakefile()
                fs.writeFileSync "#{target}",  result
