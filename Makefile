# Makefile for sslc - Fallout 2 script compiler
# macOS version

CC = clang
CFLAGS = -std=c99 -O2
LDFLAGS = 

# Target executable
TARGET = sslc

# Source files
SOURCES = compile.c \
          extra.c \
          gencode.c \
          lex.c \
          mcpp_directive.c \
          mcpp_eval.c \
          mcpp_expand.c \
          mcpp_main.c \
          mcpp_support.c \
          mcpp_system.c \
          optimize.c \
          parse.c \
          parseext.c \
          parselib.c

# Object files
OBJECTS = $(SOURCES:.c=.o)

# Default target
all: $(TARGET)

# Build the executable
$(TARGET): $(OBJECTS)
	$(CC) $(OBJECTS) -o $(TARGET) $(LDFLAGS)

# Compile source files to object files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Clean build artifacts
clean:
	rm -f $(OBJECTS) $(TARGET)

# Rebuild everything
rebuild: clean all

# Install (copy to /usr/local/bin)
install: $(TARGET)
	cp $(TARGET) /usr/local/bin/

# Uninstall
uninstall:
	rm -f /usr/local/bin/$(TARGET)

# Debug build with AddressSanitizer
debug: CFLAGS = -std=c99 -g -O0 -fsanitize=address -fsanitize=undefined -fno-omit-frame-pointer
debug: LDFLAGS = -fsanitize=address -fsanitize=undefined
debug: $(TARGET)

.PHONY: all clean rebuild install uninstall debug