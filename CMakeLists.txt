cmake_minimum_required(VERSION 3.10)
project(compile C)

# Set 32-bit flag for all targets because it segfaults on 64-bit
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -m32")

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

set(SOURCES
    compile.c
    parse.c
    parselib.c
    extra.c
    gencode.c
    lex.c
    parseext.c
    mcpp_main.c
    mcpp_directive.c
    mcpp_eval.c
    mcpp_expand.c
    mcpp_support.c
    mcpp_system.c
    optimize.c
    compat.c
)

add_executable(compile ${SOURCES})
