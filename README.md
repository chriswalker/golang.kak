# golang.kak
**golang.kak** brings additional Go functionality to [Kakoune], implementing some features from [vim-go]. It provides alternate file switching (switching from a `.go` file to its `_test.go` file, or between Go module files), and commands to run Go unit tests and display test file coverage. It does not aim to implement all features found in [vim-go], but just enough of them to provide useful additions to Kakoune's out-of-the-box Go support.

## Installation
Choose one of the following installation methods:
1. Add [`golang.kak`](rc/golang.kak) to your autoload directory
2. Source manually
3. Install via [plug.kak]

## Usage
**golang.kak** currently provides three commands:

Command | Description
------- | -----------
`go-test` | Run tests in the current package. Currently the test status is displayed in the modeline.
`go-coverage` | Display test coverage highlighters in the current file, if it is a `.go` file. Run the command again to remove coverage highlights.
`go-alternate`| Switch from a `.go` file to its associated `_test.go` file, if one exists, or vice versa. Also switches between `go.mod` and `go.sum` files.

**golang.kak** also provides syntax highlighting for `go.mod` and `go.sum` files.

## Configuration
**golang.kak**'s default highlighters for Go module files and unit test coverage are globally defined, and can be overridden after **golang.kak** has been loaded:

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

