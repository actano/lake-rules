## tj components rules

### abstract

the rule file component.coffee defines rules for building tj components

the file contains rules for compiling script files like stylus, jade and coffee script,
rules for creating a component.json out of the manifest.coffee
and for installing remote components and for building the component itself.

find the create component json tool in the file create_component_json.coffee.

### Manifest

all values are defined in the client section of the Manifest.coffee

#### script files

make target for all script files is the destination filename in the feature build directory

##### coffee client scripts

    manifest.coffee:
        client:
            scripts: [<coffee.file>, ...]
            main: coffee.file

    component.json:
        scripts: [<js.file>, ...]
        main: js.files

all entries in the client.scripts section will be compiled from coffee to javascript.
the main entry defines the component.json entry point.

##### jade templates

    manifest.coffee:
        client:
            templates: [<jade.file>, ...]
            mixins:
                require:
                    key: value
                export: [<jade.file>, ...]

    component.json:
        scripts: [<js.file>, ...]

at the client.template section jade files are defined that are compiled to javascript.
the object under the optional client.mixins.require section is passed to the jade template compiler.
jade mixins are defined under client.mixins.export

##### stylus files

    manifest.coffee:
        scripts: [<js.file>, ...]
        client:
            styles: [<stylus.file>, ...]


or alternative

    manifest.coffee:
        client:
            styles:
                files: [<stylus.file>, ...]
                dependencies: [<relative.path.to.local.feature>, ...]

    component.json:
        styles: [<css.file>, ...]


stylus files are compiled to css files. dependencies are added to the stylus compile include path.

##### image files

    manifest.coffee:
        client:
            images: [<image.file>, ...]

    component.json:
        images: [<image.file>, ...]

image files are just copied to the feature build path.

#### dependencies

##### local dependencies

    manifest.coffee:
        client:
            dependencies:
                production:
                    local: [<relative.path.to.local.feature>, ...]

    component.json:
        local: [<local.feature>, ...]
        path: [<relative.path.to.feature.dir>, ...]

local dependencies are set to the component.json and are make prerequisites for the features component.json


##### remote dependencies

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

    component.json:
        dependencies: {'<github/repo>': '<version>', ...}
        development: {'<github/repo>': '<version>', ...}


remote dependencies are set to the component.json either the dependencies section or the development section


#### component.json

the component.json make target creates the feature component.json.

the make target name is

    featureBuildPath/component.json

phony targets to create the component.json are

    featurePath/build
    build



#### component build

the component build rule installs the remote components in the feature global build component directory.
after that the component itself is build with the definitions of the component.json file.

make target for the component build is

    featureBuildPath/component-build/component-is-build

phony targets to build the component are

    featurePath/component-build





