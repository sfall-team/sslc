#ifdef _WIN32

#include <io.h>
    
#else
    
    
    
#ifndef _WINDOWS_H_DEFINED
#define _WINDOWS_H_DEFINED    

#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <stdarg.h>
int sprintf_s(char *buffer, size_t sizeOfBuffer, const char *format, ...);

#endif
#endif