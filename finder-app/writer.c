#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>

int main(int argc, char *argv[]) {
    openlog("writer", LOG_PID, LOG_USER);

    if (argc != 3) {
        syslog(LOG_ERR, "Invalid arguments. Expected 2, got %d", argc - 1);
        fprintf(stderr, "Usage: %s <file> <string>\n", argv[0]);
        closelog();
        return 1;
    }

    const char *filepath = argv[1];
    const char *text = argv[2];

    FILE *fp = fopen(filepath, "w");
    if (fp == NULL) {
        syslog(LOG_ERR, "Failed to open file: %s", filepath);
        perror("fopen");
        closelog();
        return 1;
    }

    if (fputs(text, fp) == EOF) {
        syslog(LOG_ERR, "Failed to write to file: %s", filepath);
        perror("fputs");
        fclose(fp);
        closelog();
        return 1;
    }

    syslog(LOG_DEBUG, "Writing %s to %s", text, filepath);
    fclose(fp);
    closelog();
    return 0;
}

