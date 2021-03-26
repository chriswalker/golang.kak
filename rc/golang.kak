# -----------------------------------------------------------------------------
# golang.kak
#
# This module provides additional syntax highlighting for test coverage and Go
# module files, and commands for:
# 
# - switching to alternate files,
# - running tests,
# - displaying test coverage in the current buffer, and
# - adding/removing struct tags (e.g. `json:"foo"`)
# -----------------------------------------------------------------------------

# Set Go modules filetype (.mod and .sum files)
hook global BufCreate .*/?go\.(mod|sum) %{
    set-option buffer filetype gomodfile
}

# Add Go module highlighters based on filetype
hook global WinSetOption filetype=(gomodfile) %{
    require-module golang

    add-highlighter window/gomod ref gomod

    hook -once -always window WinSetOption filetype=.* %{
        remove-highlighter window/gomod
    }
}

# Add coverage highlighters if go_display_coverage set
hook global WinSetOption go_display_coverage=true %{
    require-module golang

	add-highlighter window/gocov ref gocov

    hook -once -always window WinSetOption go_display_coverage=false %{
        remove-highlighter window/gocov
	}
}

# Whether coverage highlights are being displayed
declare-option -hidden bool go_display_coverage false
# Range spec for code covered by a test
declare-option -hidden range-specs go_covered_range
# Range spec for code not covered by a test
declare-option -hidden range-specs go_notcovered_range

provide-module golang %{

    # Check tooling dependencies; just gomodifytags currently
    evaluate-commands %sh{
       if ! command -v gomodifytags > /dev/null 2>&1; then
           printf "%s\n" "echo -markup {Error}gomodifytags is not installed, please install via 'go get'"
       fi
    }
    
    #
    # Module files (go.mod and go.sum)
    #
    set-face global Hash keyword
    set-face global Version cyan
    set-face global Dependency green
    set-face global ReplaceOperator yellow

    add-highlighter shared/gomod regions
    add-highlighter shared/gomod/comments region "//" '\n' fill comment
    add-highlighter shared/gomod/hash region "h1:" '\n' fill Hash

	add-highlighter shared/gomod/default default-region group
    add-highlighter shared/gomod/default/ regex ^go\s|module|require|replace|exclude 0:keyword
    add-highlighter shared/gomod/default/ regex \sv(\d+\.)?(\d+\.)?(\d+)([^\s]+|[\n]+) 0:Version
    # This specifically matches dependencies at the start of the line (prefixed by tab chars)
    # which has the nice effect of leaving replacements & exclusions un-highlighted
    add-highlighter shared/gomod/default/ regex ([\t]|^)([a-zA-Z0-9_\-]+\.[a-zA-Z0-9_\-]+)([^\s]+) 0:Dependency
    add-highlighter shared/gomod/default/ regex (=>) 0:ReplaceOperator
    
    #
    # Test coverage
    #
    set-face global Covered green
    set-face global NotCovered red
    set-face global Uninstrumented blue
    
    add-highlighter shared/gocov group
    add-highlighter shared/gocov/ fill Uninstrumented
    add-highlighter shared/gocov/ ranges go_covered_range
    add-highlighter shared/gocov/ ranges go_notcovered_range

    # Switch to alternate file (e.g. from foo.go -> foo_test.go, go.mod -> go.sum)
    # -----------------------------------------------------------------------------
    define-command go-alternate -docstring "(Go) Switch to alternate file" %{
        evaluate-commands %sh{
            file_root=""
       	    file_suffix=""
            # TODO - looks like alt jumping between source and test files
            # will be handled by Kakoune in next release, so will be able to
            # remove some of the below
       	    if [[ "${kak_bufname}" =~ _test\.go$ ]]; then
       	        file_root=${kak_bufname%_test*}
    	        file_suffix='.go'
            elif [[ "${kak_bufname}" =~ \.go$ ]]; then
                file_root=${kak_bufname%.go*}
                file_suffix='_test.go'
            elif [[ "${kak_buffile}" =~ go\.mod$ ]]; then
                file_suffix='go.sum'
            elif [[ "${kak_buffile}" =~ go\.sum$ ]]; then
                file_suffix='go.mod'
            else
                printf "%s\n" "fail 'Not a Go file'"
     	        exit
            fi

    		if [ ! -f ${file_root}${file_suffix} ]; then
    		    printf "%s\n" "fail '${file_root##*/}${file_suffix} does not exist'"
    		    exit
    		fi
    		
            # TODO - Check alt file is readable?
             
            printf "%s\n" "edit ${file_root}${file_suffix}"
        }
    }

    # [WIP] Run tests in current package
    # -----------------------------------------------------------------------------   
    define-command go-test -docstring "(Go) Run tests in current package" %{
        evaluate-commands %sh{
    		if [[ ! "${kak_bufname}" =~ \.go$ ]]; then
                printf "%s\n" "fail 'Not a Go file'"
    			exit
    		fi

            # Get diectory current buffer file is in & filename
            cur_dir=${kak_buffile%/*}

            go test ${cur_dir} > /dev/null 2>&1

            if [ $? == 0 ]; then
                printf "%s\n" "echo -markup '{green}Tests passed'"
            else
                printf "%s\n" "fail 'Tests failed'"
            fi
        }
    }

    # Display test coverage in the current buffer
    # -----------------------------------------------------------------------------
    define-command go-coverage -docstring "(Go) Show test coverage for the currently open file" %{
        evaluate-commands %sh{
    		if [[ ! "${kak_bufname}" =~ \.go$ ]]; then
                printf "%s\n" "fail 'Not a Go file'"
    			exit
    		fi

            # If already displaying coverage
            if [ "${kak_opt_go_display_coverage}" = "true" ]; then
                printf "%s\n" "set-option window go_display_coverage false"
                exit
            fi
            
            # Run coverage test for current directory
            go test ${kak_buffile%/*} -coverprofile=cover.out > /dev/null 2>&1

    		# Set up coverage highlighters
    		printf "%s\n" "set-option window go_covered_range %val{timestamp}"
    		printf "%s\n" "set-option window go_notcovered_range %val{timestamp}"
    		
    		# Loop through coerage file and apply faces to range-specs
    		IFS=":, "
    		grep ${kak_bufname##*/} cover.out | while read -r file start end freq covered; do
    			if [ $covered == "1" ]; then
        			range="go_covered_range"
        			face="Covered"
                else
        			range="go_notcovered_range"
        			face="NotCovered"
                fi
    		    printf "%s\n" "set-option -add window ${range} '${start},${end}|${face}'"	
    		done
    		
    		# Clean up and apply highlighters
    		rm -f cover.out
            printf "%s\n" "set-option window go_display_coverage true"
        }
    }

    # String containing constructed args for gomodifytags
    declare-option -hidden str go_modifytags_flags

    # Apply tags to the Go structure the cursor is currently within. Requires at
    # least one tag to add; multiple tags can be supplied as a comma-separated
    # list (e.g. 'go-add-tags json,yaml').
    # -----------------------------------------------------------------------------
    define-command go-add-tags -params ..1 -docstring "(Go) Add tags to the surrounding struct" %{
        set-option buffer go_modifytags_flags "-add-tags %arg{1} -offset %val{cursor_byte_offset}"
        evaluate-commands -draft %{
            execute-keys '%'
            go-modify-tags
        }
    }

    # Remove tags from the Go structure the cursor is currently within. Requires at
    # least one tag to remove; multiple tags can be supplied as a comma-separated
    # list (e.g. 'go-remove-tags json,yaml').
    # -----------------------------------------------------------------------------
    define-command go-remove-tags -params ..1 -docstring "(Go) Remove tags from the surrounding struct" %{
        set-option buffer go_modifytags_flags "-remove-tags %arg{1} -offset %val{cursor_byte_offset}"
        evaluate-commands -draft %{
            execute-keys '%'
            go-modify-tags
        }
    }

    # Internal command to modify a struct's tags; modelled on rc/tools/format.kak
    # -----------------------------------------------------------------------------
    define-command go-modify-tags -hidden %{
        evaluate-commands -draft -no-hooks -save-regs '|' %{
            set-register '|' %{
                in="$(mktemp "${TMPDIR:-/tmp}"/golang-kak-tags.XXXXXX)"
                out="$(mktemp "${TMPDIR:-/tmp}"/golang-kak-tags.XXXXXX)"

                cat > "$in"
                gomodifytags -file $in $kak_opt_go_modifytags_flags > $out
                if [ $? -eq 0 ]; then
                    cat "$out"
                else
                	# TODO - this has changed in recent commits to format.kak, so recheck this
                    # when next version of Kakoune is released to see if 'fail' now works here
                    printf 'eval -client %s %%{ echo -markup %%{{Error}gomodifytags returned an error - check debug buffer} }' "$kak_client" | kak -p "$kak_session"
                    cat "$in"
                fi
                rm -f "$in" "$out"
            }
            execute-keys '|<ret>'
        }
    }
}

require-module golang
