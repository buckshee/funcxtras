function funclate
	if test (count $argv) -eq 0
        echo "Usage: funclate [prefix, first function or collation name] [function names]..."
        return 1
    end
    set funcdir ~/.fish/functions
    if test (count $argv) -eq 1
        if test ! -f $funcdir/$argv.fish
            echo "Single arguments must be a function prefix"
            return 1
        else
            set file_list (find $funcdir/ -name "$argv*.fish")
        end
    else if test (count $argv) -gt 1
        if test ! -f $funcdir/$argv[1].fish
            echo "Funclation name $argv[1]"
            set funclation $argv[1]
            set argstart 2
        else
            set argstart 1
        end
        echo -n "Adding functions: "
        for x in (seq $argstart (count $argv))
            set -a file_list $funcdir/$argv[$x].fish
            echo -n "$argv[$x] "
        end
        echo ""
    end

    if test (count $file_list) -eq 0
        echo "Empty file list?"
        return 1
    else
        if test -z $funclation
            set funclation ~/$argv.funclation.fish
        else
            set funclation ~/$funclation.funclation.fish
        end
        if test -f $funclation
            echo "Overwriting existing collation"
        end
        echo "Collating "(count $file_list)" functions"
        cat $file_list >$funclation
        cat $funclation | string match -r '^function.*' | string replace function funcsave >>$funclation
        ls -lh $funclation
    end
end
function funcdump
	set function_path ~/.fish/functions
    if test -f "$function_path/$argv[1].fish"
        echo
        cat $function_path/$argv[1].fish
        echo
    else
        if test -f "$function_path/$argv[2].fish"
            switch "$argv[1]"
                case 'k'
                    cat $function_path/$argv[2].fish | kdialog --textbox -
                case 'x'
                    cat $function_path/$argv[2].fish | xclip -selection clipboard
                    echo "copied to clipboard"
                case 'i'
                    cat $function_path/$argv[2].fish | while read x
                        echo "    "$x
                    end | xclip -selection clipboard
                    echo "indented and copied to clipboard"
                case '*'
                    echo "(k)dialog (x)clip (i)ndented"
            end
        else
            echo "function not found"
        end
    end
end
funcsave funclate
funcsave funcdump
