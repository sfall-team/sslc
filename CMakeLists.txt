cmake_minimum_required(VERSION 3.10)

set(EXECUTABLE_NAME sslc)

project(${EXECUTABLE_NAME})

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

add_executable(${EXECUTABLE_NAME} ${SOURCES})


if(${CMAKE_SYSTEM_NAME} MATCHES "Emscripten")
  set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -g")
  set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g")

  set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O1")
  set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O1")

  set(CMAKE_EXECUTABLE_SUFFIX ".mjs")


  target_link_options(${EXECUTABLE_NAME} PRIVATE "-sASYNCIFY")
  target_link_options(${EXECUTABLE_NAME} PRIVATE "-sASYNCIFY_STACK_SIZE=20480")

  target_link_options(${EXECUTABLE_NAME} PRIVATE "-sALLOW_MEMORY_GROWTH")
  target_link_options(${EXECUTABLE_NAME} PRIVATE "-MEMORY_GROWTH_LINEAR_STEP=32mb")
  target_link_options(${EXECUTABLE_NAME} PRIVATE "-sNO_DISABLE_EXCEPTION_CATCHING")

  target_link_options( ${EXECUTABLE_NAME} PRIVATE "-lnodefs.js" )
  # target_link_options(${EXECUTABLE_NAME} PRIVATE "-sNODERAWFS")

  # Disabled because of emscipten bug
  # target_link_options( ${EXECUTABLE_NAME} PRIVATE "-sCASE_INSENSITIVE_FS" )

  target_link_options(${EXECUTABLE_NAME} PRIVATE "-sMODULARIZE=1")

  target_link_options(${EXECUTABLE_NAME} PRIVATE "-sEXPORT_ES6=1")

  target_link_options(${EXECUTABLE_NAME} PRIVATE "-sENVIRONMENT=node")


  target_link_options(${EXECUTABLE_NAME} PRIVATE "-sEXPORTED_RUNTIME_METHODS=callMain,addRunDependency,removeRunDependency")
  target_link_options(${EXECUTABLE_NAME} PRIVATE "-sEXPORT_ALL")

  target_link_options(${EXECUTABLE_NAME} PRIVATE "-sEXIT_RUNTIME")
  target_link_options(${EXECUTABLE_NAME} PRIVATE "$<$<CONFIG:DEBUG>:-g>")


  set(PACKAGE_JSON_CONTENT [[
  {
    "name": "sslc-emscripten-nodefs",
    "version": "1.0.0",
    "description": "",
    "main": "sslc.mjs",
    "type": "module",
    "scripts": {
    },
    "author": "",
    "license": "UNLICENSED"
  }

  ]])
  file(WRITE ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/package.json "${PACKAGE_JSON_CONTENT}")

endif()

