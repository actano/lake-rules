path = require 'path'

module.exports =
    config:
        lakeOutput: path.join process.cwd(), 'build', 'lake'
        featureBuildDirectory: '$(LOCAL_COMPONENTS)'
        remoteComponentPath:'$(REMOTE_COMPONENTS)'
        runtimePath: '$(RUNTIME)'
