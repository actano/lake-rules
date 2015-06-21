Rule = require './rule'

BUILD_SERVER = '$(BUILD_SERVER)'

shellEscape = (s) ->
    return '"' + s.replace(/[\\"]/g, '\\$&').replace(/\n/g, '\\\\n') + '"'

command = (cmd, args...) ->
    args.push '$@' if args.length < 1
    args[0] = '$@' unless args[0]?
    args.push '$<' if args.length < 2
    args[1] = '$<' unless args[1]?
    args.unshift cmd
    while not args[args.length - 1]?
        args.pop()
    return "@exit $(shell printf #{shellEscape args.join '\n'} | nc localhost $(BUILD_SERVER_PORT) || echo 90)"

Rule::buildServer = (cmd, args...) ->
    @orderOnly BUILD_SERVER
    @action command.apply this, arguments
    return this

module.exports = {command}
