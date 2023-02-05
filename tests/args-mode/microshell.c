#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <stdbool.h>

static int  save_stdin;

static bool __cmd_is(char *this, char *cmd) {
    return (!strcmp(this, cmd) ? true : false);
}

static bool __dup(int original, int clone) {
    return ((dup2(original, clone) == -1) ? false : true);
}

static int  __strlen(char *s) {
    char    *ptr =s;
    while (*ptr)
        ptr++;
    return (ptr - s);
}

static bool __is_operator(char *this) {
    if (__cmd_is("|", this)
        || __cmd_is(";", this))
        return (true);
    return (false);
}

static bool do_cd(char **av, int ac) {
    if (ac != 2)
        return (write(2, "error: cd: bad arguments\n", 25),
			false);
    if (chdir(av[1]))
        return (
            write(2, "error: cd: cannot change directory to ", 38),
            write(2, av[1], __strlen(av[1])),
            write(2, "\n", 1),
            false);
    return (true);
}

static int  execute(int ac, char **av, char **env) {
	pid_t	pid;
    int		p[2];
	int		ret;
    bool	is_pipe;

    ret = 0;
	is_pipe = (av[ac] && __cmd_is("|", av[ac]));
    if (is_pipe && (pipe(p)))
        return (write(2, "error: fatal\n", 13),
			EXIT_FAILURE);
    if ((pid = fork()) == 0)
    {
        av[ac] = NULL;
        if (!__dup(save_stdin, STDIN_FILENO)
			|| close(save_stdin)
			|| (is_pipe
                && (!__dup(p[1], STDOUT_FILENO)
                    || close(p[0])
                    || close(p[1]))))
            return (write(2, "error: fatal\n", 13),
                EXIT_FAILURE);
        execve(av[0], av, env);
        return (
            write(2, "error: cannot execute ", 22),
            write(2, av[0], __strlen(av[0])),
            write(2, "\n",1),
			EXIT_FAILURE);
    }
    else if (pid == -1)
        return (write(2, "error: fatal\n", 13),
			EXIT_FAILURE);
    is_pipe ? false : waitpid(pid, &ret, 0);
    if ((is_pipe && (!__dup(p[0], save_stdin)
			|| close(p[0])
        	|| close(p[1])))
		|| (!is_pipe && !__dup(STDIN_FILENO, save_stdin)))
        return (write(2, "error: fatal\n", 13),
            EXIT_FAILURE);
    return ((WIFEXITED(ret) ?
        WEXITSTATUS(ret) : EXIT_SUCCESS));
}

int main(int ac, char *av[], char **env) {
    int cur;
    int cmd_size;

    cur = 0;
    save_stdin = dup(STDIN_FILENO);
    while (++cur < ac)
    {
        cmd_size = 0;
        while (cur + cmd_size < ac
			&& !__is_operator(av[cur + cmd_size]))
            cmd_size++;
        if (__cmd_is("cd", av[cur])
			&& !do_cd(av + cur, cmd_size))
            return (EXIT_FAILURE);
        else if (cmd_size
			&& execute(
                cmd_size, av + cur, env) != EXIT_SUCCESS)
            return (EXIT_FAILURE);
        cur += cmd_size;
    }
    while (waitpid(0, NULL, 0) != -1)
        ;
    if (!__dup(STDIN_FILENO, save_stdin))
		return (
            write(2, "error: fatal\n", 13),
            EXIT_FAILURE);
    return (EXIT_SUCCESS);
}
