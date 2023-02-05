gcc microshell.c -o microshell &&
./tester.sh -c -p ./microshell -m args-mode
rm -f microshell
rm -rf outfiles