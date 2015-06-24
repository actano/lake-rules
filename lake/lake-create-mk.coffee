# Third party
nopt = require 'nopt'
debug = require('debug')('local-make')

# Local dep
{createMakefiles} = require('./create_makefile')

knownOpts =
    help: String
    version: Boolean

shortHands =
    h: ['--help']
    v: ['--version']

parsedArgs = nopt(knownOpts, shortHands, process.argv, 2)

if parsedArgs.help
    console.log 'USAGE'
    console.dir shortHands
    return

debug 'createMakefiles'
createMakefiles parsedArgs.input, parsedArgs.output
    .catch (err) ->
        console.error err.stack
        process.exit 1
