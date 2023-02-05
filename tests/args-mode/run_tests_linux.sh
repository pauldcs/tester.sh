gcc microshell.c -o microshell &&
./tester.sh -v -p ./microshell -m args-mode
rm -f microshell
rm -rf outfiles