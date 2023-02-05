gcc microshell.c -o microshell &&
./tester.sh -vc -p ./microshell -m args-mode
rm -f microshell
rm -rf outfiles