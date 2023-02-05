#include <stdlib.h>
#include <unistd.h>
#include <stddef.h>

#ifndef BUFFER_SIZE
# define BUFFER_SIZE 42
#endif

int __strlen(char *s)
{
	char *ptr = s;
	while (*ptr)
		ptr++;
	return (ptr - s);
}
char *__strdup(char *s)
{
	char *ptr = malloc(__strlen(s) + 1);
	char *tmp = ptr;
	while (*s)
		*tmp++ = *s++;
	*tmp = '\0';
	return (ptr);
}
char *__strjoin(char *s1, char *s2)
{
	int len = __strlen(s1) + __strlen(s2);
	char *ptr = malloc(len + 1);
	char *tmp = ptr;
	char *to_free = s1;
	while (*s1)
		*tmp++ = *s1++;
	while (*s2)
		*tmp++ = *s2++;
	*tmp = '\0';
	free(to_free);
	return (ptr);
}
char *__strchr(char *s, char c)
{
	while (*s)
	{
		if (*s == c)
			return (s);
		s++;
	}
	return (NULL);
}
char *get_next_line(int fd)
{
	static char arr[BUFFER_SIZE];
	static char *save = NULL;
	char *line = NULL;
	char *tmp = NULL;
	int ret = 0;
	if (save)
	{
		line = save;
		save = NULL;
	}
	else
	{
		line = malloc(1);
		*line = 0;
	}
	while ((tmp = __strchr(line , '\n')) == NULL)
	{
		ret = read(fd, arr, BUFFER_SIZE);
		if (!ret || ret == -1)
			break ;
		arr[ret] = 0;
		line = __strjoin(line, arr);
	}
	if (tmp)
	{
		save = __strdup(++tmp);
		*tmp = 0;
	}
	if (!*line)
	{
		free(line);
		return (NULL);
	}
	return (line);
}

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
char *get_next_line(int fd);
int	main(int ac, char **av) {
	char	*line;
	int 	fd;
	if (ac == 2) {
		if ((fd = open(av[1], O_RDONLY)) == -1)
			return(fprintf(stderr, "open() error\n"), EXIT_FAILURE);
		while ((line = get_next_line(fd)) != NULL) {
			printf ("%s", line);
			free(line);
		} return (EXIT_SUCCESS);
	} return (EXIT_FAILURE);
}