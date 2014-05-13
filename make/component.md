# Component

## Abstract

Defines rules for creating a [tj components](http://component.io/) component.json.

It contains rules for compiling script files like Stylus, Jade and CoffeeScript
and creating a `component.json`.

The script `create_component_json.coffee` belongs to this rule file and is
responsible for generating the `component.json`.

## Targets

The build targets build all resources needed by the component and generate a
component.json. They do _not_ invoke "component-build".

- `featurePath/build` builds all resources and the component.json
- `build` builds all features

## Manifest

All entries are located in the client section inside the manifest.

### Script Files

Script files can either be CoffeScript, Jade or Stylus files.

#### CoffeeScript Client Scripts

CoffeeScript scripts are located in the "client.scripts" and "client.main" section:

    manifest.coffee:
        client:
            scripts: [<coffee.file>, ...]
            main: coffee.file

CoffeeScript scripts will be compiled to Javascript. The main entry defines the
component.json entry point.

The generated component.json has the following format:

    component.json:
        scripts: [<js.file>, ...]
        main: js.files


#### Jade Templates

Jade temples are located in the "client.templates" section.

    manifest.coffee:
        client:
            templates:
                files: ['<jade.file>', ]
                dependencies: [<path.to.other.feature>, ...]

The templates are added to the component.json like so:

    component.json:
        scripts: [<js.file>, ...]

#### Stylus Files

Stylus files can be declared in two variants. Either directly in the
"client.styles" section for with dependencies in "client.styles.files" and
"client.styles.dependencies" respectively.

Directly, without dependencies:

    manifest.coffee:
        client:
            styles: [<stylus.file>, ...]


Using dependencies:

    manifest.coffee:
        client:
            styles:
                files: [<stylus.file>, ...]
                dependencies: [<relative.path.to.local.feature>, ...]

Stylus files are compiled to CSS, where any dependencies are added to the
include path. The generated CSS files are referenced in the component.json in
the "styles" section:

    component.json:
        styles: [<css.file>, ...]


#### Image Files

Images are specified in the manifest section "client.images" and copied directly
to the build directory.

    manifest.coffee:
        client:
            images: [<image.file>, ...]

The files are referenced in the component.json in the "images" section:

    component.json:
        images: [<image.file>, ...]

### Dependencies

#### Local Dependencies

Dependencies to other, local features can be specified in the
"client.dependencies.production.local" section.

    manifest.coffee:
        client:
            dependencies:
                production:
                    local: [<relative.path.to.local.feature>, ...]

They are added to the component.json under the "local" section. The path will be
set to the local feature directory such that the dependency can be resolved.

    component.json:
        local: [<local.feature>, ...]
        path: [<relative.path.to.feature.dir>, ...]


#### Remote Dependencies

Dependencies to remote components are specified in sections
"client.dependencies.production.remote" and/or
"client.dependencies.development.remote".

    manifest.coffee:
        client:
            dependencies:
                production:
                    remote:
                        '<github/repo>': '<version>'
                        ...
                development
                    remote:
                        '<github/repo>': '<version>'
                        ...

They are written to component.json in sections "dependencies" and "development"
respectively.

    component.json:
        dependencies: {'<github/repo>': '<version>', ...}
        development: {'<github/repo>': '<version>', ...}
