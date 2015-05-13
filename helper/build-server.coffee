shellEscape = (s) ->
    return '"' + s.replace(/[\\"]/g, '\\$&').replace(/\n/g, '\\\\n') + '"'

command = (cmd, args...) ->
    args.push '$@' if args.length < 1
    args[0] = '$@' unless args[0]?
    args.push '$<' if args.length < 2
    args[1] = '$<' unless args[1]?
    args.unshift cmd
    return "@exit $(shell printf #{shellEscape args.join '\n'} | nc localhost $(BUILD_SERVER_PORT) || echo 90)"

prereq = (prerequisites = []) ->
    need = '$(BUILD_SERVER)'
    orderOnly = false
    for k in prerequisites
        return prerequisites if k is need
        orderOnly = true if k is '|'
    prerequisites.push '|' unless orderOnly
    prerequisites.push need
    prerequisites

module.exports = {command, prereq}
