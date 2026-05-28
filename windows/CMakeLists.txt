cmake_minimum_required(VERSION 3.14)
project(MuseFlow LANGUAGES CXX)

set(BINARY_NAME "museflow")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

include(FetchContent)
FetchContent_MakeAvailable(Qt6)

set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")

add_subdirectory(${FLUTTER_MANAGED_DIR})

add_dependencies(${BINARY_NAME} FlutterAssemble)
