#ifdef _WIN32

#else

#ifndef _COMPAT_STRING_H_DEFINED
#define _COMPAT_STRING_H_DEFINED    
        
int strcpy_s(char* dest, size_t destsz, const char* src);
int strcat_s(char *dest, size_t destsz, const char *src);

#define _stricmp strcasecmp

#endif
#endif