# Architecture vision of the build system

## Requirements

The build system should adhere to the following requirements:

+ It is __simple and transparent__.

  This means that it is easy to understand. The rules are simple and
  explicit.

+ It is __fast__.

  This means that it builds incrementally. Only the necessary files are
  built. Changed source files trigger a rebuild of the target files.

+ It is __correct__.

  This means that changing a source file rebuilds all necessary files. An incremental
  build leads to the same result as a fresh, complete build.

+ It is __documented__.

  This means that global targets and rules are documented within the build
  system. And that this file must exist.

## Implementation

The build system implmentation follows the following guide lines:

+ A feature (also known as submodule, component, package) is fully
  described by its Manifest.
+ The Manifest declares all parts belonging to the feature.
+ The Manifest declares all dependencies of the feature to other
  local or remote features and modules.
+ Rules are organized by logical components like tj components,
  rest-api's, webapp, stylus, etc.
+ Every rule takes a section/entry of the Manifest declaration and
  compiles this to a set of make actions.
+ Rules can ask other rules for there prerequisites by calling the
  otherRuleSet.getTargets() method.
+ Build things top-down to avaoid unnecessary rules and files.
+ Rely only on information in the Manifest to generate rules.
+ Write small, atomic rules.
+ Avoid phony targets.

## Diagram

temporary [picture in confluence](https://confluence.actano.de/display/RX/Architecture+vision)

