# Translations

## Abstract

Generates translation files for alien.

## Targets

None of the targets generated by this rule need to be called manually. They are
referenced by the tj component rules.

## Manifest

Translations are specified in section "client.translations" as pairs of
language code and translation file.

Each language will be compiled to Javascript and placed at
"featureBuildPath/translations/languageCode.js".

Additionally, an index file is generated at "featureBuildPath/translations/index.js"
which can be used with alien to access the translations.

    manifest.coffee
        client:
            translations:
                'de_DE':    '<file.coffee>'
                'en_US':    '<file.coffee>'