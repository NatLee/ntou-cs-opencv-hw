# Builds the seven programs, one executable per folder, named after the folder.
#
# They were written for OpenCV 3: they use its old C API (IplImage, cvShowImage, cvCreateTrackbar, …),
# which OpenCV 4 removed, and TextDetection needs the contrib "text" module. The Dockerfile has a
# matching toolchain (Ubuntu 18.04, OpenCV 3.2).
#
#   mkdir build && cd build && cmake .. && make
#
# Run a program from its own folder, e.g. `cd TextDetection4Ways && ../build/TextDetection4Ways`:
# they open their input files (TEST.jpg, 0.txt … 9.txt, 7.jpg, model files) by relative path.
cmake_minimum_required(VERSION 3.10)
project(ntou-cs-opencv-hw LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(OpenCV 3 REQUIRED COMPONENTS core imgproc highgui videoio video objdetect features2d text)

# add_program(<folder> <source files in that folder>…)
function(add_program folder)
  set(sources "")
  foreach(file IN LISTS ARGN)
    list(APPEND sources "${folder}/${file}")
  endforeach()
  add_executable(${folder} ${sources})
  target_include_directories(${folder} PRIVATE ${OpenCV_INCLUDE_DIRS})
  target_link_libraries(${folder} PRIVATE ${OpenCV_LIBS})
endfunction()

add_program(TextDetection main.cpp TextDetection.cpp TEXTRecognizer.cpp)
add_program(TextDetection4Ways Source.cpp)  # Source.cpp includes thinning.cpp itself
add_program(TextDetectionUsingProfile Source.cpp)
add_program(NecklineDetectionUsingNormalMethod NecklineDetection.cpp)
add_program(NecklineDetectionUsingOpticalFlow NecklineOpticalFlow.cpp find_collar.cpp)
add_program(heartbeats main.cpp heartbeats.cpp skin_color.cpp)
add_program(FaceAndHeartbeatDetection FaceDetection.cpp heartbeats.cpp skin_color.cpp)
