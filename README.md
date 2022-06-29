# Fresh 

Fresh is a command line tool that builds and (re)starts your web application everytime you save a Go file.

## Installation

    go get github.com/seantcanavan/fresh

## Usage

    cd fresh
    go install

Start fresh:

    fresh

This assumes that your $GOPATH/bin is added to your $PATH variable. This enables the `fresh` binary to be accessed in any project folder.

Fresh will watch for file events, and every time you create/modify/delete a file it will build and restart the application.
If `go build` returns an error, it will log it in the tmp folder.

`fresh` uses `./runner.conf` for configuration by default, but you may specify an alternative config filepath using `-c`:

    fresh -c other_runner.conf

Here is a sample config file with the default settings:

    root:              .
    tmp_path:          ./tmp
    build_name:        runner-build
    build_log:         runner-build-errors.log
    valid_ext:         .go, .tpl, .tmpl, .html
    no_rebuild_ext:    .tpl, .tmpl, .html
    ignored:           assets, tmp
    build_delay:       600
    colors:            1
    log_color_main:    cyan
    log_color_build:   yellow
    log_color_runner:  green
    log_color_watcher: magenta
    log_color_app:


## Author

* [Andrea Franz](http://gravityblast.com)
* [seantcanavan](https://github.com/seantcanavan)
