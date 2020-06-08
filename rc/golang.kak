# -----------------------------------------------------------------------------
# golang.kak
#
# This module provides ddditional syntax highlighting for test coverge and Go
# module files, and commands for switching to alternate files, running tests and
# displayed test coverage in the current buffer.
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
            # bufname
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

}

require-module golang
