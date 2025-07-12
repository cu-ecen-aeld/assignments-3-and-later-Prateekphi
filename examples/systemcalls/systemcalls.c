#include "systemcalls.h"
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <fcntl.h>

/**
 * @brief Run a command using system()
 * 
 * @param cmd Command string (e.g., "echo hello > file.txt")
 * @return true if the command succeeded, false otherwise
 */
bool do_system(const char *cmd)
{
    if (cmd == NULL) return false;
    int ret = system(cmd);
    return (ret == 0);
}

/**
 * @brief Execute a command with execv, no shell involved
 * 
 * @param count Number of arguments (e.g., 3)
 * @param ... The command and args (e.g., "/bin/echo", "hello", "world")
 * @return true if execv succeeds, false otherwise
 */
bool do_exec(int count, ...)
{
    va_list args;
    va_start(args, count);
    char *command[count + 1];

    for (int i = 0; i < count; i++) {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;
    va_end(args);

    pid_t pid = fork();
    if (pid == -1) return false;

    if (pid == 0) {
        // In child
        execv(command[0], command);
        perror("execv failed");
        exit(1);
    } else {
        // In parent
        int status;
        waitpid(pid, &status, 0);
        return WIFEXITED(status) && WEXITSTATUS(status) == 0;
    }
}

/**
 * @brief Executes a command like do_exec(), but redirects output to a file
 * 
 * @param outputfile Where to redirect stdout
 * @param count Number of arguments
 * @param ... Command arguments
 * @return true if successful
 */
bool do_exec_redirect(const char *outputfile, int count, ...)
{
    va_list args;
    va_start(args, count);
    char *command[count + 1];

    for (int i = 0; i < count; i++) {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;
    va_end(args);

    pid_t pid = fork();
    if (pid == -1) return false;

    if (pid == 0) {
        int fd = open(outputfile, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (fd < 0) {
            perror("open failed");
            exit(1);
        }
        dup2(fd, STDOUT_FILENO);  // Redirect stdout
        close(fd);

        execv(command[0], command);
        perror("execv failed");
        exit(1);
    } else {
        int status;
        waitpid(pid, &status, 0);
        return WIFEXITED(status) && WEXITSTATUS(status) == 0;
    }
}

