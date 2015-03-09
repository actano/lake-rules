# Third party
nopt = require 'nopt'
debug = require('debug')('local-make')

# Local dep
{createMakefiles} = require('./create_makefile')

knownOpts =
    input: [String, Array]
    output: String
    help: String
    version: Boolean

shortHands =
    i: ['--input']
    o: ['--output']
    h: ['--help']
    v: ['--version']

parsedArgs = nopt(knownOpts, shortHands, process.argv, 2)

if parsedArgs.help
    console.log 'USAGE'
    console.dir shortHands
    process.exit 0

debug 'createMakefiles'
err = createMakefiles parsedArgs.input, parsedArgs.output
if err?
    console.error err.message
    process.exit 1
else
    process.exit 0
