# golang.kak
**golang.kak** brings additional Go functionality to [Kakoune], implementing some of the features found in [vim-go]. Over Kakoune's built-in Go functionality, it provides:

* Syntax highlighting for Go module files (`go.mod` and `go.sum`),
* Alternate file switching (switch from a `.go` file to its `_test.go` file, or between `go.mod` and `go.sum` files) via `go-alternate`,
* Execution of Go unit tests via `go-test`,
* Display test file coverage in the current buffer via `go-coverage`, and
* Some basic struct tag handling via `go-add-tags` and `go-remove-tags`.

It does not aim to implement all features found in [vim-go], but just enough of them to provide useful additions to Kakoune's out-of-the-box Go support.

## Dependencies
`golang.kak` requires [gomodifytags] in order to add/remove struct tags. `gomodifytags` can be installed by running:

```
go get github.com/fatih/gomodifytags
```

If the `gomodifytags` binary is not found in `$GOBIN`, the plugin will output an error indicating this when invoking the `go-add-tags` or `go-remove-tags` commands; a missing `gomodifytags` binary will not prevent other plugin features from working.

Future versions of the plugin will provide a better UI around tooling dependencies.

## Installation
Choose one of the following installation methods:
1. Add [`golang.kak`](rc/golang.kak) to your autoload directory
2. Source manually
3. Install via [plug.kak] or similar plugin managers

## Usage
**golang.kak** provides five commands:

Command | Description
------- | -----------
<nobr>`go-test`|Run tests in the current package. Currently the test status is displayed in the modeline.
<nobr>`go-coverage`|Display test coverage highlighters in the current file, if it is a `.go` file. Run the command again to remove coverage highlights.
<nobr>`go-alternate`|Switch from a `.go` file to its associated `_test.go` file, if one exists, or vice versa. Also switches between `go.mod` and `go.sum` files.
<nobr>`go-add-tags`|Add the specified tag (or tags, as a comma-separated list) to the struct the cursor is currently within. `go-add-tags` is additive, and each successive execution within a struct will add new tags to its fields.
<nobr>`go-remove-tags`|Remove a specified tag (or tags, as a comma-separated list) from the struct the cursor is currently within. `go-remove-tags` is subtractive and each successive execution within a struct will remove further tags from its fields.

## Configuration
**golang.kak** does not require any specific configuration. However, its provided highlighters for Go module files and unit test coverage are globally defined, and can be overridden after **golang.kak** has been loaded:

### Module files
Face | Description
---- | -----------
`Hash` | Colour of dependency hash values in `go.sum` files
`Version` | Colour of dependency versions in Go module files
`Dependency` | Colour of dependency names in `go.mod` and `go.sum` files
`ReplaceOperator` | Colour of the `=>` operator in `go.mod` files

### Test Coverage
Face | Description
---- | -----------
`Covered` | Colour of code covered by unit tests
`Uncovered` | Colour of code not covered by unit tests
`Uninstrumented` | Colour of code not instrumented by `go test`

## Acknowledgements
This plugin is inspired by [vim-go]; therefore grateful thanks are due to Fatih Arslan (creator of [vim-go]) and all contributors to that project. Thank you, all.

[Kakoune]: https://kakoune.org
[vim-go]: https://github.com/fatih/vim-go
[plug.kak]: https://github.com/andreyorst/plug.kak
[gomodifytags]: https://github.com/fatih/gomodifytags

