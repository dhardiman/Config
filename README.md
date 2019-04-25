# Config
[![CircleCI](https://circleci.com/gh/dhardiman/Config.svg?style=svg)](https://circleci.com/gh/dhardiman/Config)

This is a command line tool for generating configuration files from a custom JSON schema. Loosely based on [ConfigGenerator](https://github.com/theappbusiness/ConfigGenerator), but significantly more extensible.

##### Why not just use ConfigGenerator?
Because each configuration requires a completely separate input file, it doesn't allow for sharing values across configurations, and it also makes it too easy to forget to add values across every configuration.

### How to use
Simply pass a folder and a scheme name to the command:
```
generateconfig --configPath /path/to/my/config --scheme my-scheme-name
```

`generateconfig` will find all files with a `.config` file extension, search for a suitable template, and output a .swift file for each file.

## Schemas
### Default
A sample of the schema is:

```
{
  "template": {
    "imports": [ "MyCustomFramework" ]
  },
  "key": {
    "description": "An optional comment to document the property. Will be added as a comment to the generated code",
    "type": "String",
    "defaultValue": "value to be used by all schemes",
    "overrides": {
      "scheme pattern 1": "a different string to be used by schemes matching 'scheme pattern 1'",
      "scheme pattern 2": "a different string to be used by schemes matching 'scheme pattern 2'"   
    }
  },
  "group: {
    "key": {
      "type": "String",
      "defaultValue": "value to be used by all schemes",
      "overrides": {
        "scheme pattern 1": "a different string to be used by schemes matching 'scheme pattern 1'",
        "scheme pattern 2": "a different string to be used by schemes matching 'scheme pattern 2'"   
      }
  }
}
```

The "key" will be used as a static property name in a `class` so should have a format that is acceptable to the swift compiler. Most likely `lowerCamelCase`.

`type` can have the following values:

- `String`: A swift string value
- `URL`: A url. Will be converted to `URL(string: "the value")!`
- `Int`: An integer value.
- `Double`: A double value
- `Bool`: A boolean value
- `Colour`: A colour in hex format, will be output as a `UIColor`.
- `Image`: The name of an image. Will be converted to `UIImage(named: "the value")!`.
- `EncryptionKey`: A key to use to encrypt sensitive info.
- `Encrypted`: A value that should be encrypted using the provided key
- `Dictionary`: A dictionary. Keys should be strings, values in the dictionary should be either string, numeric, or a new dictionary.
- `Reference`: See [Reference Properties](#reference-properties) below.
- Enum types. Set the `type` to the name of the enum, set the value to be the case, preceded by a `.`, so `.thing`. If you need enums from a custom module, add a string array of imports to the template section.

`overrides` contains values that are different to the provided `defaultValue`. The keys in this dictionary should be a regex pattern to match the scheme passed in. The values should be the same type as the `defaultValue` as specified by `type`. If two overridden values could match, the first suitable value found is used. `overrides` is optional, if not provided, all schemes will use the `defaultValue`.

Note properties can also be grouped together as per the second example. Any number of properties can be added to a named group, which will create a nested class within the parent config class with the properties attached.

#### Associated Properties

Sometimes you may want to map a property to the output of another property, rather than a passed in scheme. Take the example below:

```
{
  "host": {
    "type": "String",
    "defaultValue": "example.com",
    "overrides": {
      "test": "test.example.com",
      "stage": "test.example.com",
      "live": "live.example.com"   
    }
  },
  "logoName": {
    "type": "String",
    "defaultValue" "logo.png",
    "associatedProperty": "host",
    "overrides": {
      "test.example.com": "logo-test.png"
    }
  }
}
```

The `logoName` property has an `associatedProperty`, which ties it's `overrides` to the value of `host` instead of the passed in scheme. This allows for more concise override lists, as in the example above both the "test" and "stage" scheme will produce a "logo-test.png" logoName.

Note that there are a couple of caveats when using `associatedProperty`:

- The keys in `overrides` do not use regular expression pattern matching, and instead require an exact string match.
- The `associatedProperty` _must_ have a String type.

#### Reference Properties

Sometimes you may want to make a property return the output of another property, depending on the passed in scheme. For example:
```
{
  "red": {
    "type": "Colour",
    "defaultValue": "#FF0000"
  },
  "green": {
    "type": "Colour",
    "defaultValue": "#00FF00"  
  },
  "textColour": {
    "type": "Reference",
    "defaultValue": "red",
    "overrides": {
      "greenScheme": "green"
    }
  }
}
```

The `textColour` property will be `return red` for all schemes bar the `greenScheme` where it will be `return green`.

### Enum
This schema should be used for creating enums.
A sample of the schema is:

```
{
  "template": {
    "name": "enum",
    "rawType": "String"
  },
  "key": {
    "defaultValue": "",
    "overrides": {
      "scheme pattern 1": "a dffierent string to be used by schemes matching 'scheme pattern 1'"
    }
  }
}
```

`template.name` defines which template code `config` should use to parse this file. `template.rawType` specifies the raw enum type to use. Currently only "String" is supported. The properties follow the same rules as the default, however `type` is not required. If no value is provided for `defaultValue` and no `overrides` are present, the enum key will also be the raw value.

### Extensions
This schema should be used for creating extensions on existing classes.
A Sample of the schema is:

```
{
  "template": {
    "extensionOn": "UIColor",
    "extensionName": "Palette",
    "requiresNonObjC": true
  },
  "brand": {
    "type": "Colour",
    "defaultValue": "#FF0000",
    "overrides": {
      "blue": "#0000FF"
    }
  }
}
```

This will output an extension on `UIColor` in a file called `UIColor+Palette.swift`.

### Custom types
It is possible to use your own custom types with config. Add a `customTypes` array to your `template` section and you can then add your values, either as a string, for single values, or as a keyed dictionary. For example:

```
{
  "template": {
    "customTypes": [
      {
        "typeName": "MyCustomType",
        "initialiser": "MyCustomType(thing: {$0})"
      },
      {
        "typeName": "MyMoreComplexCustomType",
        "initialiser": "MyMoreComplexCustomType(thing: {thing}, otherThing: {otherThing:String})"
      }
    ]
  },
  "myThing": {
    "type": "MyCustomType",
    "defaultValue": "Thingy"
  },
  "myOtherThing": {
    "type": "MyMoreComplexCustomType",
    "defaultValue": {
      "thing": "Thingy",
      "otherThing": "A different thingy"
    }
  }
}
```

Placeholders in the initialiser template should be written as `{key}` or `{key:TypeHint}` where the type hint is one of the basic primitive types, `Bool`, `String`, `URL`, `Int`, `Double`. If no type hint is supplied then the value is treated as an expression.

## Writing your own schemas
Just add a new class or struct to the project and implement `Template`. Add your new parser to the `templates` array in main.swift. Your template should inspect a `template` dictionary in any config and decide whether it can parse it. Either using a `name` item, or through other means. Ensure `ConfigurationFile` is the last item in that array. As the default schema parser it claims to be able to parse all files.

As new templates can be written from scratch, there is no pre-defined schema that your json file should adhere to, but for the sake of readability for other contributors, it would probably be sensible if it resembled the default schema as closely as possible.
