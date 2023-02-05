gcc get_next_line.c -o get_next_line &&
./tester.sh -p ./get_next_line -m path-mode
rm -f get_next_line
rm -rf outfiles
