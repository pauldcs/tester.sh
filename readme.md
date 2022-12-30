```
    tester.sh
    By: pducos <pducos@student.42.fr>

SYNOPSIS
    ./tester.sh [-p program] [-s suffix] [-i input_directory] [-o output_directory] [-v] [-h]
        [-c] [-r output_file] [-m mode]

DESCRIPTION
    This script is used to test a program by running it on a set of input files
    and comparing its output to the expected output. The script takes several command line
    options such as the name of the program to test, the suffix of the input files, 
    and the directories containing the input and expected output files.
    
    The `-c` (compare) argument enables reports when the infile does not match the
      outfile. 
    
    The `-m` argument specifies the mode in which the tests should be run. 
      If the mode is "args-mode" (default), the content of the infile is passed
      as arguments to the program. 
      If the mode is "path-mode", the path to the infile is passed as arguments to the program.
      If the mode is "command-mode", the infile's content is executed.

    By default, the script runs the program on files with the ".in" suffix in the
    "infiles" directory and writes the program's output to the "outfiles" directory. It then
    compares the actual output with the expected output in the "infiles" directory, both of
    which must have the ".out" suffix. The script can also be run under Valgrind to check for
    memory errors.
```