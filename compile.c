#define WIN32_LEAN_AND_MEAN
#define _CRT_RAND_S
#include <stdio.h>
#include <stdlib.h>
#include "lex.h"
#include "parse.h"

#ifdef _WIN32
#include <Windows.h>
#include <io.h>
#else
#include "compat.h"
#endif

#include "resource.h"

#ifdef BUILDING_DLL
int optimize = 0;
#else
int optimize = 1; // default for exe
#endif

int noinputwait = 0;
int warnings = 1;
int backwardcompat = 0;
int debug = 0;
int preprocess_fullpath = 0;
int dumpTree = 0;
int shortCircuit = 0;
FILE *parseroutput;

#define FINDDATA _finddata_t
#define FINDFIRST(x, y) _findfirst(x, y)
#define FINDNEXT(x, y) _findnext(x, y)
#define FINDCLOSE(x, y) _findclose(x)
#define FINDHANDLE long
//#define BAD_HANDLE -1

#if defined(_MSC_VER)
#define FIND_SUCCESS(x)	((x) != -1)
#else
#define FIND_SUCCESS(x)	((x) == 0)
#endif

static void PrintLogo() {
	parseOutput("Startrek Scripting Language compiler (Fallout 2 sfall edition " VERSION_STRING ")\n\n"
#ifndef WIN2K
		"Preprocessing handled by mcpp 2.7.2\n"
		"Copyright (c) 1998, 2002-2008 Kiyoshi Matsui <kmatsui@t3.rim.or.jp>\n"
		"All rights reserved.\n\n"
#else
		"Win2K/Lite version (with no built-in preprocessor)\n\n"
#endif
	);
}

extern int warn_level; // the mcpp warning level
extern int mcpp_lib_main(FILE *fin, FILE *fout, const char* in_file, const char* dir, const char* def, const char* include_dir);
extern void mcpp_add_include_dir(char*);

#ifndef BUILDING_DLL
int main(int argc, char **argv)
{
	InputStream foo;
	char name[260], *c, *file;
	struct FINDDATA buf;
	FINDHANDLE handle;
	int nologo = 0;
	int preprocess = 0;
	int onlypreprocess = 0;
#ifndef WIN2K
	char tmp_file_name[260] = {0};
#endif

	char* includeDir = NULL, *defMacro = NULL;

	if (argc < 2) {
		PrintLogo();
		parseOutput("Usage: compile {switches} filename [-o outputname] [filename [..]]\n");
		parseOutput("  -q    don't wait for input on error\n");
		parseOutput("  -n    no warnings\n");
		parseOutput("  -b    use backward compatibility mode\n");
		parseOutput("  -l    no logo\n");
#ifndef WIN2K
		parseOutput("  -p    preprocess source\n");
		parseOutput("  -P    preprocess only (don't generate .int)\n");
		parseOutput("  -F    write full file paths in #line directives\n");
#endif
		parseOutput("  -O<level>  optimize code\n");
		parseOutput("             0 - none\n");
		parseOutput("             1 - only remove unreferenced variables/procedures (default)\n");
		parseOutput("             2 - full (same as -O)\n");
		parseOutput("             3 - full+experimental, don't use!\n");
		parseOutput("  -d    show debug info\n");
		parseOutput("  -s    enable short-circuit evaluation for boolean operators (AND, OR)\n");
		parseOutput("  -D    dump abstract syntax tree after optimizations\n");
#ifndef WIN2K
		parseOutput("  -m<macro>[=<val>]  define a macro named \"macro\" for conditional compilation\n");
		parseOutput("  -I<path>  specify an additional directory to search for include files\n");
#endif
		return 1;
	}

	while ((argv[1] != NULL) && (argv[1][0] == '-')) {
		switch(argv[1][1]) {
		case 'w':
		case '-':
			break;
		case 'n':
			warnings=0;
			warn_level=0;
			break;
		case 'q':
			noinputwait=1;
			break;
		case 'd':
			debug=1;
			break;
		case 'b':
			backwardcompat = 1;
			break;
		case 'l':
			nologo=1;
			break;
		case 'O':
			if (strlen(argv[1]) == 2) optimize = 2; // full
			else optimize = atoi(&argv[1][2]);
			break;
#ifndef WIN2K
		case 'P':
			onlypreprocess = 1;
		case 'p':
			preprocess = 1;
			break;
		case 'F':
			preprocess_fullpath = 1;
			break;
#endif
		case 'D':
			dumpTree = 1;
			break;
		case 's':
			shortCircuit = 1;
			break;
#ifndef WIN2K
		case 'm':
			defMacro = &argv[1][2];
			break;
		case 'I':
			if (!includeDir)
				includeDir = &argv[1][2];
			else
				mcpp_add_include_dir(&argv[1][2]);
			break;
#endif
		default:
			parseOutput("Unknown option %c\n", argv[1][1]);
		}

		argv++;
		argc--;
	}
	// disabled - Fakels
	/*if (backwardcompat&&(optimize||preprocess)) {
		parseOutput("Invalid option combination; cannot run preprocess or optimization passes in backward compatibility mode\n");
		return -1;
	}*/

	if (!nologo) PrintLogo();

	compilerErrorTotal = 0;
#ifndef WIN2K
	if (defMacro) parseOutput("Define macro: %s\n", defMacro);
	if (includeDir) parseOutput("Set include directory: %s\n", includeDir);
#endif
	while (argv[1]) {
		file = argv[1];
		argv++;
		argc--;

		if (FIND_SUCCESS(handle = FINDFIRST(file, &buf))) {
			do {
				foo.name = AddFileName(buf.name);

				if ((foo.file = fopen(buf.name, "r")) == 0) {
					parseOutput("Couldn't find file %s\n", buf.name);
					return -1;
				}

				parseOutput("Compiling %s\n", buf.name);

				if (argc >= 2 && !strcmp(argv[1], "-o")) {
					argv += 2;
					argc -= 2;
					strcpy_s(name, 260, argv[0]);
				} else {
					strcpy_s(name, 260, buf.name);
					c = strrchr(name, '.');

					if (c) {
						*c = 0;
					}

					if (onlypreprocess) {
						strcat_s(name, 260, ".preprocessed.ssl");

						if (strcmp(name, buf.name) == 0) {
							c = strrchr(name, '.');
							*c = 0;
							*--c = 0;
							strcat_s(name, 260, "1.preprocessed.ssl");
						}
					} else {
						strcat_s(name, 260, ".int");

						if (strcmp(name, buf.name) == 0) {
							c = strrchr(name, '.');
							*c = 0;
							*--c = 0;
							strcat_s(name, 260, "1.int");
						}
					}
				}
#ifndef WIN2K
				if (preprocess) {
					FILE *newfile;
					unsigned int letters;

					rand_s(&letters);
					if (onlypreprocess) {
						strcpy_s(tmp_file_name, 260, name);
						newfile = fopen(tmp_file_name, "w+");
					} else {
						sprintf(tmp_file_name, "%d_%8x.tmp", GetCurrentProcessId(), letters);
//#if _DEBUG
//						newfile = fopen(tmp_file_name, "w+");
//#else
#ifdef WIN32
						newfile = fopen(tmp_file_name, "w+DT");
#else
						newfile = fopen(tmp_file_name, "w+");
#endif
//#endif
					}
					if (mcpp_lib_main(foo.file, newfile, buf.name, buf.name, defMacro, includeDir)) {
						parseOutput("*** An error occured during preprocessing of %s ***\n", buf.name);
#ifndef WIN32
						if (strlen(tmp_file_name) > 0) {
							remove(tmp_file_name);
						}
#endif
						return 1;
					}
					fclose(foo.file);
					rewind(newfile);
					foo.file = newfile;
				}
#endif
				if (!onlypreprocess) {
					parse(&foo, name);
					freeCurrentProgram();
				}
				fclose(foo.file);
#ifndef WIN32
				if (strlen(tmp_file_name) > 0) {
					remove(tmp_file_name);
				}
#endif
				FreeFileNames();
			} while (!FINDNEXT(handle, &buf));

			FINDCLOSE(handle, &buf);

			if (compilerErrorTotal) {
				parseOutput("\n*** THERE WERE ERRORS (%u of them) ***\n", compilerErrorTotal);
				if (!noinputwait)
					getchar();
				return 1;
			}
		} else {
			parseOutput("Warning: %s not found\n", file);
		}
	}
	return 0;
}
#endif

#ifdef BUILDING_DLL

static int inited = 0;

int _stdcall parse_main(const char *filePath, const char* origPath, const char* dir/*, const char* def, const char* include_dir, int backMode*/) {
	InputStream foo;
	char tmpbuf[260];
	//char cwd[1024];
	FILE *newfile;
	unsigned int letters;

	if (inited) {
		freeCurrentProgram();
		FreeFileNames();
		inited=0;
	}
/*
	if (backMode) {
		backwardcompat = 1;
		lexClear();
	}
*/
	foo.name = AddFileName(origPath);
	foo.file = fopen(filePath, "r");

	rand_s(&letters);
	sprintf(tmpbuf, "%d_%8x.tmp", GetCurrentProcessId(), letters);
	newfile = fopen(tmpbuf, "w+DT");
	//newfile = fopen(tmpbuf, "w+");
	parseroutput = fopen("errors.txt", "w");
	//GetCurrentDirectoryA(1024, cwd);
	//chdir(dir);
	compilerErrorTotal = 0;
	compilerSyntaxError = 0;
	preprocess_fullpath = 1;
	if (mcpp_lib_main(foo.file, newfile, origPath, dir, NULL, NULL)) { // prevent crash in old Script Editor - NR
		fclose(foo.file);
		fclose(newfile);
		if (parseroutput)
			fclose(parseroutput);
		return 2;
	}
	//chdir(cwd);

	fclose(foo.file);
	//fflush(newfile);
	rewind(newfile);
	foo.file = newfile;
	parse(&foo, NULL);
	fclose(foo.file);

	inited = 1;
	if (parseroutput)
		fclose(parseroutput);

	return (compilerErrorTotal) ? 1 : (compilerSyntaxError) ? -1 : 0;
}

#endif
