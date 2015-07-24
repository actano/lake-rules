cp = require 'child_process'
path = require 'path'
coffee = require.resolve 'coffee-script/bin/coffee'

child_module = path.join __dirname, 'build-server', 'index.coffee'
args = [child_module, process.argv.slice(2)...]

child = cp.fork coffee, args
child.on 'exit', (code, signal) ->
    console.error 'Forked Worker quit unexpected with code %s', code
    process.exit code || 1

child.on 'message', (msg) ->
    if msg is 'running'
        console.log "Build server running with pid #{child.pid}"
        child.disconnect()
        process.exit 0
