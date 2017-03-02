# Bash Common

> **Current status**: Work in progress; most of the functionality is tested and safe to use. Lacks documentation.

A set of curated bash formula, ready to consume. It provides a simplistic module loading with dependency management and support for loading variants of modules based on bash version.

## Modules

Below are the current set of modules provided. For information on functions provided by each of them, please have a look inside.

> *NOTE*: The function documentation is similar to what is [prescribed by google](https://google.github.io/styleguide/shell.xml?showone=Function_Comments#Function_Comments), but in a minimised form.
>
> *Example:*
> ```
> # Check major version of bash to be at least a given number
> #
> # Arguments:
> #   1. major_version version to check against
> #
> # Returns:
> #   0 if greater than or equal to major_version, otherwise 1
> is_bash_version() {
> ...
> }
> ```

 * [array](array.sh)
 * [logging](logging.sh)
 * [misc](misc.sh)
 * [namespaced-variables](namespaced-variables.sh)
 * [posix-mode](posix-mode.sh)
 * [semver](semver.sh)
 * [string](string.sh)
 * [validate](validate.sh)
 
#### Other
 * [common](common.sh)

## Examples

 * [Logging; how to?](examples/logging.sh)

## Contributing

Bug reports, feature requests, commentary, and pull requests; they all count. Please do feel free to fork and make changes.

If you would like your changes to be merged back, please follow the below basic rules.

 * All major changes must be accompanied by an issue. For typos and trivial updates, I am happy to over look that.
 * All changes must pass a [shellcheck](https://www.shellcheck.net/).
 * More documentation the merrier; especially functions. If they are hard to use, do provide an example.
 * All changes must be accompanied by appropriate tests.
 * All changes must be bash 3.2+ compatible.
 
   > *I dont have access to bash 3.2+; how do I test it?*
   >
   > A Linux distro version to ship with v3.2 is CentOS 5. You can use a VM or docker to perform these tests. If you choose the latter, the formula to run can be.
   >
   > ```text
   > docker run -v $(pwd):/bash-common --rm -it -w /bash-common centos:5 sh /bash-common/run-tests.sh
   > ```
   
   

## License

[MIT License](LICENSE.md)

Copyright (c) 2017 Dino Korah