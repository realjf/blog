---
title: "Windows下 Vscode Cpp开发环境配置"
date: 2020-09-14T15:59:09+08:00
keywords: ["posts", "vscode"]
categories: ["posts"]
tags: ["posts", "vscode", "cpp"]
series: [""]
draft: false
toc: false
related:
  threshold: 80
  includeNewer: false
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

### 前期准备
- win10 系统
- 安装好vscode
- 安装好git
- 安装好cmake for windows
- 安装好mingw64
- 安装好visual studio 2019/2017

> 本次c++开发项目主要依赖于cmake和visual studio作为编译工具
### 开始配置vscode
#### 首先打开vscode，安装一下插件

- ms-vscode.cpptools
- ms-vscode.cmake-tools
- formulahendry.code-runner

#### 然后开始c++配置
按住ctrl+p，打开vscode的命令模式,
输入"> edit Configurations"，然后选择
c/c++ edit Configurations(JSON)，打开
c_cpp_properties.json文件

#### 开始编辑c_cpp_properties.json文件
```json
{
    "configurations": [
        {
            "name": "GCC",
            "includePath": [
                "${workspaceFolder}/**",
                "C:\\Program Files (x86)\\oatpp\\include\\oatpp-1.1.0\\oatpp" // 这里添加第三方库目录
            ],
            "defines": [
                "_DEBUG",
                "UNICODE",
                "_UNICODE"
            ],
            "windowsSdkVersion": "10.0.15063.0",
            "compilerPath": "E:\\mingw-w64\\x86_64-8.1.0-posix-seh-rt_v6-rev0\\mingw64\\bin\\g++.exe", // 这里改成你安装mingw64下的g++.exe文件路径
            "cStandard": "c11",
            "cppStandard": "c++17",
            "intelliSenseMode": "gcc-x64" // 这里是模式选择
        }
    ],
    "version": 4
}
```
配置完成后，在vscode的工作目录下有个.vscode文件夹
里面会有c_cpp_properties.json文件

#### 开始编写代码
```shell script
# 新建目录
make test 
cd test
# 新建文件
type null > src/main.cpp
type null > CMakeLists.txt
```
写代码，然后写CMakeLists.txt，内容如下
```shell script
# 写CMakeLists.txt文件，其内容如下
cmake_minimum_required(VERSION 3.1)

set(project_name oatpp_example) ## rename your project here

project(${project_name})

set(CMAKE_CXX_STANDARD 11)

add_library(${project_name}-lib
        src/main.cpp
)

## link libs
find_package(oatpp 1.1.0 REQUIRED)

target_link_libraries(${project_name}-lib
        PUBLIC oatpp::oatpp
        PUBLIC oatpp::oatpp-test
)

target_include_directories(${project_name}-lib PUBLIC src)

## add executables

add_executable(${project_name}-exe
        src/main.cpp)

target_link_libraries(${project_name}-exe ${project_name}-lib)
add_dependencies(${project_name}-exe ${project_name}-lib)
```
以上都准备完毕，开始编译代码

#### 编译代码：非cmake方式
如果不使用cmake，可以直接忽略CMakeLists.txt文件编写，直接选中入口文件，然后按f5运行code running，进行编译，
首次运行会出现配置launch.json，其配置如下：
```shell script
{
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
            "name": "g++.exe - 生成和调试活动文件",
            "type": "cppdbg",
            "request": "launch",
            "program": "${fileDirname}\\${fileBasenameNoExtension}.exe",
            "args": [],
            "stopAtEntry": false,
            "cwd": "${workspaceFolder}",
            "environment": [],
            "externalConsole": true,
            "MIMode": "gdb",
            "miDebuggerPath": "E:\\mingw-w64\\x86_64-8.1.0-posix-seh-rt_v6-rev0\\mingw64\\bin\\gdb.exe", // 改成你自己的gdb路径
            "setupCommands": [
                {
                    "description": "为 gdb 启用整齐打印",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ],
            "preLaunchTask": "g++.exe" // 该名称需要与后面task.json中的label属性名称一致
        }
    ]
}
```
接下来是配置task.json文件，内容如下：
```shell script
{
    // See https://go.microsoft.com/fwlink/?LinkId=733558
    // for the documentation about the tasks.json format
    "version": "2.0.0",
    "tasks": [
        {
            "type": "shell",
            "label": "g++.exe", // 该名称需要与launch.json里的preLaunchTask里的名称一致
            "command": "E:\\mingw-w64\\x86_64-8.1.0-posix-seh-rt_v6-rev0\\mingw64\\bin\\g++.exe", // 改成你自己的g++路径
            "args": [
                "-Wall",
                "-g",
                "${file}",
                "-I'C:/Program Files (x86)/oatpp/include/oatpp-1.1.0/oatpp'", // 这里是库文件查找目录
                "-o",
                "${fileDirname}\\${fileBasenameNoExtension}.exe"
            ],
            "options": {
                "cwd": "F:\\shared\\vscode_projects"
            },
            "problemMatcher": [
                "$gcc"
            ]
        }
    ]
}
```
配置好后，就可以编译运行了

#### 编译代码：cmake方式

```shell script
# 在项目目录下新建build文件
mkdir build
cd build
# 运行cmake
cmake ..
```
运行结束后，使用visual studio 2019/2017打开build目录下的sln文件，
打开后，在ALL BUILD文件夹上右击，选择生成，编译完成后，在build/Debug/下可以看到生成的可执行文件





