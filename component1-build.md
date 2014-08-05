# Component

## Abstract

Defines rules for building [tj components](http://component.io/) (component version 1.x).

It takes care of installing remote components and building the actual
component.


## Targets

The component1-build target builds the "main component" (aka "root component") of this feature.

- `featurePath/component1-build` 

Building a main component is usually done as needed, e.g. for pages, demo html pages or when
running tests. It can be forced by using the `featurePath/component1-build`
target.

## Manifest

Rules are added if a client section exists inside the manifest. No further entries are required.

The rule has a component.json prerequisite taken from the component rule `getTargets()` method.

Component build output is generated into a "component1-build" directory at the buildPath of the feature.
Remote dependencies are installed into the "feature global" `build/remote_components_v1` directory.

NOTE: As long as we are using component version 0.x as well as component version 1.x make targets for both
will be generated.