## Architecture vision of the build system

### Requirements

+ the build system is simple, transparent, easy to understand and not complex.
+ the build system is defined by simple explicit rules.
+ the build system is fast and robust.
+ the incremental build step, builds everything what is required, but not more then necessary.
+ the incremental build leads to the same result as a complete build (with a clean before)

### Implementation

+ a feature (aka submodule, component, package) is fully described by its Manifest.
+ the Manifest declares all parts belonging to the feature.
+ the Manifest declares all dependencies of the feature to other local or remote features and modules.
+ rules are composed by logical components like tj components, rest-api's, webapp, stylus, etc.
+ every rule takes a section/ entry of the Manifest declaration and compiles this to a set of make actions.
+ rules can ask other rules for there prerequisites by calling the otherRuleSet.getTargets() method.
  because of that dependencies between ruleSets are find explicit in the code

### picture

temporary find the picture in confluence -> https://confluence.actano.de/display/RX/Architecture+vision

