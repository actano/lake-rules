# Component

## Abstract

Defines rules for building [tj components](http://component.io/).

It takes care of installing remote components and building the actual
component.


## Targets

The component-build target builds the "main component" (aka "root component") of this feature.

- `featurePath/component-build` 

Building a main component is usually done as needed, e.g. for pages, demo html pages or when
running tests. It can be forced by using the `featurePath/component-build`
target.

## Manifest

rules are added if a client section exists inside the manifest. no further entries are required.

the rule has a component.json prerequisite taken from the component rule getTargets() method.

component build output is generated into a "component-build" directory at the buildPath of the feature.
remote dependencies are installed into the "feature global" build/remote  
