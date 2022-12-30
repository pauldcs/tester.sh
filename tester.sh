#!/bin/bash

PROG=$(basename $0)

show_usage() {
    cat <<EOF
Usage: $0 [options]

Options
    -m   <mode>
          The mode in which to run the tests. This option is optional,
          and the default mode is "args-mode".
          Available:
              - 'args-mode'
              - 'path-mode'
              - 'command-mode' 
    -p   <program>
          The program to test. This option is required.
    -s   <input_file_suffix>
          The suffix of the input files. This option is optional,
          and the default value is "in". 
    -i   <input_directory>
          The directory containing the input files. This option is optional,
          and the default value is "infiles".
    -o   <output_directory>
          The directory to write the output files to.
          This option is optional, and the default value is "outfiles".
    -v   Run the tests under Valgrind. This option is optional,
          and the default value is false.
    -c   Do infile / outfile comparisons.
    -r   <output_file>
          Redirect the output of the tests to the specified file.
          This option is optional, and the default value is false.
    -h   Show this usage message.

EOF
}

if [ $# -eq 0 ] ;
    then
        show_usage
	    exit 1
fi

DEFAULT_PROGRAM="None"
DEFAULT_MODE="args-mode"
DEFAULT_INPUT_SUFFIX="in"
DEFAULT_INPUT_DIRECTORY="infiles"
DEFAULT_OUTPUT_DIRECTORY="outfiles"

OK_COLOR=$(tput setaf 2)
ERROR_COLOR=$(tput setaf 1)
BOLD_UNDERLINE=$(tput bold)$(tput smul)
NO_COLOR=$(tput sgr0)

while getopts "p:s:i:o:m:cvr:h" opt; do
    case $opt in
        p) program_name="$OPTARG";;
        m) mode="$OPTARG";;
        s) input_file_suffix="$OPTARG";;
        i) input_directory="$OPTARG";;
        o) output_directory="$OPTARG";;
        v) run_under_valgrind=true;;
        r) do_redirection="$OPTARG";;
        c) compare=true;;
        h) show_usage; exit 0;;
        \?) exit 1;;
    esac
done


# OPTIONS
program_name=${program_name:-$DEFAULT_PROGRAM}
mode=${mode:-$DEFAULT_MODE}
input_file_suffix=${input_file_suffix:-$DEFAULT_INPUT_SUFFIX}
input_directory=${input_directory:-$DEFAULT_INPUT_DIRECTORY}
output_directory=${output_directory:-$DEFAULT_OUTPUT_DIRECTORY}
run_under_valgrind=${run_under_valgrind:-false}
do_redirection=${do_redirection:-false}
compare=${compare:-false}

# Takes an error message as arguments, 
# prints it and exits with 1
exit_with_error() {
    local error_message="$1"
    >&2 printf "$PROG: %s\n" "$error_message"
    >&2 printf "$PROG: quitting...\n"
    exit 1
}

# Writes the text into a file instead 
# of stdout if the agrument -r was specified
output() {
    local output="$1"

    if [ "$do_redirection" != false ];
        then
            printf "%s\n" "$output" >> "$do_redirection"
    else
        printf "%s\n" "$output"
    fi
}

# Checks the parameters before starting the tests
check_prerequisites() {
    # Check that program_name is an absolute path to an executable file
    if [ ! -x "$program_name" ]; then
        exit_with_error "$program_name (-p): Not an executable file" 
    fi

    # Check that input_directory exists and is readable
    if [ ! -d "$input_directory" ]; then
        exit_with_error "$input_directory (-i): Not found" 
    elif [ ! -r "$input_directory" ]; then
        exit_with_error "$input_directory (-i): Not readable" 
    fi

    # Check that input_directory is not empty
    if [ -z "$(ls -A $input_directory/*.$input_file_suffix 2> /dev/null)" ]; then
        exit_with_error "$input_directory (-i): Is empty" 
    fi

    # Check that output_directory exists and is writable
    if [ ! -d "$output_directory" ]; then
        mkdir -vp "$output_directory" &> /dev/null
    elif [ ! -w "$output_directory" ]; then
        exit_with_error "$output_directory (-o): Not writable" 
    fi

    # Check that valgrind is installed and executable, if run_under_valgrind is set to true
    if [ "$run_under_valgrind" = true ] && [ ! -x "$(command -v valgrind)" ]; then
        exit_with_error "valgrind (-v): Not found" 
    fi
}

__content_as_args() {
    local input_file="$1"
    local actual_output_file="$2"
    local valgrind_log_file="$3"

    if [ "$run_under_valgrind" = true ];
        then
            cat "$input_file"                          \
            | xargs                                    \
            valgrind                                   \
                -q                                     \
                --leak-check=full                      \
                --show-leak-kinds=all                  \
                --track-origins=yes                    \
                --log-file=$valgrind_log_file          \
                --error-exitcode=1                     \
                "$program_name" &> "$actual_output_file"
    else
        cat "$input_file"                      \
        | xargs                                \
        "$program_name" &> "$actual_output_file"
    fi
    exit_code=$?
    return $exit_code
}

__file_path_as_args() {
    local input_file="$1"
    local actual_output_file="$2"
    local valgrind_log_file="$3"

    if [ "$run_under_valgrind" = true ];
        then
            valgrind                                                 \
                -q                                                   \
                --leak-check=full                                    \
                --show-leak-kinds=all                                \
                --track-origins=yes                                  \
                --log-file=$valgrind_log_file                        \
                --error-exitcode=1                                   \
                "$program_name" "$input_file" &> "$actual_output_file"
    else
        "$program_name" "$input_file" &> "$actual_output_file"
    fi
    exit_code=$?
    return $exit_code
}

__file_as_command() {
    local input_file="$1"
    local actual_output_file="$2"

    if [ "$run_under_valgrind" = true ];
        then
            >&2 "Notice: valgrind cannot be anabled by the tester in this mode"
    fi
    $program_name $input_file &> $actual_output_file
    exit_code=$?
    return $exit_code
}

# Run one test and print the results
run_test() {
    local name="$1"
    local input_file="$2"
    local actual_output_file="$3"
    local valgrind_log_file="$4"
    local expected_output_file="$5"

    output "$((passed + failed + skipped)). $name"
    output "    └── Input: $input_file"

    if [ "$mode" = "args-mode" ];
        then
            __content_as_args         \
                "$input_file"         \
                "$actual_output_file" \
                "$valgrind_log_file"
    elif [ "$mode" = "path-mode" ];
        then
             __file_path_as_args      \
                "$input_file"         \
                "$actual_output_file" \
                "$valgrind_log_file"
    elif [ "$mode" = "command-mode" ];
        then
            __file_as_command         \
                "$input_file"         \
                "$actual_output_file" \
                "$valgrind_log_file"
    else
        exit_with_error "\$mode (-m): Not supported"
    fi
    exit_code=$?
    
    # Remove leading and trailing whitespaces from both the
    # expected and actual output
    # sed -i 's/^[ \t]*//;s/[ \t]*$//' "$actual_output_file"
    # sed -i 's/^[ \t]*//;s/[ \t]*$//' "$expected_output_file"

    if [ ! -f "$actual_output_file" ] ;
        then
            output "    └── Status: ${ERROR_COLOR}Incomplete${NO_COLOR}"
            output "        └── Reason: Actual output not found"
            ((failed++))
            return
    fi
    output "    └── Output: $actual_output_file"
    output "        └── Return code: $exit_code"
    
    if [ "$compare" = true ];
        then
            if cmp -s "$actual_output_file" "$expected_output_file"; 
                then
                    output "        └── Status: ${OK_COLOR}OK${NO_COLOR}"
                    ((passed++))
            else
                output "        └── Status: ${ERROR_COLOR}KO${NO_COLOR}"
                output "            └── Expected: $expected_output_file"
                output "            └── Actual: $actual_output_file" 
                output "            └── Diff:"
                output \
                    "$(\
                        2>&1                    \
                        diff --color -Tp        \
                        "$actual_output_file"   \
                        "$expected_output_file" \
                        | sed 's/^/                /'
                    )"
                ((failed++))
            fi
    else
        ((skipped++))
    fi

    if [ -s "$valgrind_log_file" ];
        then
            sed -i 's/^==[0-9]*== //' "$valgrind_log_file"
            output "    └── Valgrind:"
            output "        └── ${ERROR_COLOR}MEMORY ERROR${NO_COLOR}"
            output \
                "$(\
                    2>&1                     \
                    cat "$valgrind_log_file" \
                    | sed 's/^/          /'
                )"
            ((memory_errors++))
    fi
    output ""
}

print_summary() {
    cat << EOF                                                                                                                                
    
    Summary:                   
    -----------------------------
    Tests Passed:  $passed - $memory_errors    
    Tests Failed:  $failed      
    Tests Skipped: $skipped                                  

                                                     
EOF
}

############################ START #############################

check_prerequisites

passed=0
failed=0
skipped=0
memory_errors=0

# Loops through the infiles in the $input_directory
for file in "$input_directory"/*."$input_file_suffix"; 
    do
        filename=$(basename -- "$file")
        test_name="${filename%.*}"

        run_test                                \
            "$test_name"                        \
            "$file"                             \
            "$output_directory/$test_name.out"  \
            "$output_directory/$test_name.valg" \
            "$input_directory/$test_name.out"
done

# print the summary of the tests
# end exit according to the results

print_summary

if [ $failed -eq 0 ];
    then
        if [ $memory_errors -eq 0 ];
            then
                exit 0
        fi
fi

exit 1

# pducos <pducos@student.42.fr>
# 30.12.22
