# Makefile for writer
CC = $(CROSS_COMPILE)gcc
CFLAGS = -Wall -Werror -g -static

TARGET = writer
SRC = writer.c

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC)

clean:
	rm -f $(TARGET) *.o

