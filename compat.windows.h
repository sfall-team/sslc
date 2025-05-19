#ifdef _WIN32

#include <windows.h>

#else


#define GetCurrentProcessId() ((unsigned int)getpid())



#endif