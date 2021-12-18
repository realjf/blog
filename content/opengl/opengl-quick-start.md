---
title: "opengl之一 快速开始 Opengl Quick Start"
date: 2020-05-07T19:45:37+08:00
keywords: ["opengl"]
categories: ["opengl"]
tags: ["opengl"]
series: [""]
draft: false
toc: false
related:
  threshold: 50
  includeNewer: true
  toLower: false
  indices:
  - name: keywords
    weight: 100
  - name: tags
    weight: 90
  - name: categories
    weight: 50
  - name: date
    weight: 10
---

### 准备
- Ubuntu OS v20.04
- glfw v3.3.4
- glad
  - gl v4.6 core
- cmake v3.18.4


### 目录结构
```sh
.
├── CMakeLists.txt
├── deps
│   ├── glad
│   │   ├── include
│   │   │   ├── glad
│   │   │   │   └── glad.h
│   │   │   └── KHR
│   │   │       └── khrplatform.h
│   │   └── src
│   │       └── glad.c
│   └── glfw
├── preinstall.sh
├── src
│   ├── CMakeLists.txt
│   ├── glad.c
│   ├── main.cpp

```
- deps 项目依赖的头文件、库文件
- deps/glad glad目录
- deps/glfw glfw目录
- preinstall.sh 提前安装预制开发环境
- src 源文件目录

### 下载

```sh
# 下载Glfw
wget https://github.com/glfw/glfw/releases/download/3.3.4/glfw-3.3.4.zip
unzip glfw-3.3.4.zip

# 将解压后的文件夹复制到deps目录下，重命名为glfw
```

浏览器打开 https://glad.dav1d.de/ ，language选择c/c++，specification选择opengl，
API的gl（即opengl）选择version 4.6， profile选择core，然后下拉到底，点击generate生成对应的glad文件，
然后下载.zip文件，最后解压后复制到deps目录下，重命名为glad即可。

之后，将glad/src下的glad.c文件复制到src目录下

### 编写文件
preinstall.sh文件内容
```sh
#!/bin/sh
apt-get install -y cmake gcc g++ make build-essential libglew-dev libopengl-dev libx11-dev libxi-dev \
    libxcursor-dev libxrandr-dev libxinerama-dev libglfw3-dev libxxf86vm-dev \
    libgl1-mesa-dev libglu1-mesa-dev
```

项目根目录下的CMakeLists.txt文件内容

```cmake
cmake_minimum_required(VERSION 3.8 FATAL_ERROR)

project(opengl)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 99)

# glfw header files
set( GLFW_INCLUDE_DIR ${opengl_SOURCE_DIR}/deps/glfw/include )
set( GLFW_DEPS_INCLUDE_DIR ${opengl_SOURCE_DIR}/deps/glfw/deps )
# glad header files
set( GLAD_INCLUDE_DIR ${opengl_SOURCE_DIR}/deps/glad/include )

list( APPEND opengl_INCLUDE ${GLFW_INCLUDE_DIR})
list( APPEND opengl_INCLUDE ${GLFW_DEPS_INCLUDE_DIR})
list( APPEND opengl_INCLUDE ${GLAD_INCLUDE_DIR})

if(WIN32)
    set(COMMON_LIBS optimized glfw opengl32 ${GLFW_LIBRARIES} ${OPENGL_LIBRARIES})
elseif (UNIX)
    set(COMMON_LIBS glfw X11 GL GLEW Xrandr Xi Xxf86vm Xcursor Xinerama pthread GLU dl GLU)
else()
    set(COMMON_LIBS)
endif()


include_directories( ${opengl_INCLUDE} )

# defines targets and sources
add_subdirectory(src)
```
src/main.cpp文件内容

```cpp
#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <iostream>

void framebuffer_size_callback(GLFWwindow* window, int width, int height);
void processInput(GLFWwindow *window);

const unsigned int SCR_WIDTH = 800;
const unsigned int SCR_HEIGHT = 600;

int main()
{
    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    // create window
    GLFWwindow* window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "LearnOpenGL", NULL, NULL);
    if (window == NULL)
    {
        std::cout << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        return -1;
    }
    glfwMakeContextCurrent(window);

    // viewport size
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

    // init glad
    if(!gladLoadGL()) { 
        return -1;
    }

    while (!glfwWindowShouldClose(window))
    {
        // input
        // -----
        processInput(window);

        // render
        // ------
        glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);     

        // glfw: swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
        // -------------------------------------------------------------------------------
        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwTerminate();
    return 0;
}

void processInput(GLFWwindow *window)
{
    if(glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(window, true);
}

void framebuffer_size_callback(GLFWwindow* window, int width, int height)
{
    glViewport(0, 0, width, height);
}

```

src/CMakeLists.txt文件内容

```cmake
set(SOURCE_FILES main.cpp glad.c)
add_executable(example ${SOURCE_FILES})

target_link_libraries(example 
    PUBLIC 
    ${COMMON_LIBS})
```
### 编译安装

```sh
# 首先运行预制安装命令
./preinstall.sh
# 然后再根目录下新建build目录进行构建即可
mkdir build
cmake ..
# 运行编译成功的文件
./src/example
```

至此，一个简单的opengl程序完成。
