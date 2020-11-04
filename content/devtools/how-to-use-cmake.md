---
title: "如何使用cmake - How to Use Cmake"
date: 2020-11-04T09:24:08+08:00
keywords: ["devtools", "cmake"]
categories: ["devtools"]
tags: ["devtools", "cmake"]
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

## 准备
- cmake

> 下载地址：https://cmake.org/download/

### 安装
具体的安装方法参照官网，这里不做赘述

### 建议
cmake每次运行会产生大量中间文件，可以通过在项目根目录下创建build文件，然后运行cmake ../执行项目构建

### cmake命令行选项
#### 指定构建系统生成器： -G
使用-G可以指定编译器，当前平台支持的编译器名称可以通过帮助手册查询cmake --help，

```shell script
# 使用vs2017构建工程
cmake -G "Visual Studio 15 2017" ../
# 使用MinGW 
cmake -G "MinGW Makefiles"
# 使用unix makefiles
cmake -G "Unix Makefiles"
```
#### CMakeCache.txt文件
- 当cmake第一次运行一个空的构建的时候，他会创建一个CMakeCache.txt文件，
文件里存放了一些可以用来制定工程的项目，比如：变量、选项等

- 对于同一变量，如果cache文件里面有设置，那么CMakeLists文件里就会优先使用Cache文件里面的同名变量。

- CMakeLists里面通过设置了一个Cache里面没有的变量，那么就将这个变量的值写入到Cache里面

#### 添加变量到cache文件中： -D
- 注意：-D后面不能有空格，如：cmake -DCMAKE_BUILD_TYPE:STRING=Debug

#### 从Cache文件中删除变量：-U
- 此选项和-D功能相反，从Cache文件中删除变量，支持使用*和？通配符

#### cmake命令行模式：-E

- cmake提供了很多和平台无关的命令，在任何平台都可以使用：chdir, copy,copy_if_different等
- 可以使用：cmake -D help进行查询

#### 打印运行的每一行cmake

- 命令行选项中：--trace，将打印运行的每一行cmake
- 命令：--trace-source="filename" 就会打印出有关filename的执行

#### 设置编译参数

- add_definitions (-DENABLED)，当在cmake里面添加该定义的时候，如果代码里面定义了#ifdef ENABLED #endif 相关的片段，此时代码里面这一块代码就会生效
- //add_definitions("-Wall -ansi -pedantic -g")
- 该命令现已经被取代，使用：add_compile_definitions(WITH_OPENCV2)

#### 设置默认值命令：option

- option命令可以帮助我们设置一个自定义的宏，如：option(MY-MESSAGE "this is my message" ON)
- 第一个参数就是我们要设置的默认值的名字
- 第二个参数是对值的解释，类似于注释
- 第三个值是这个默认值的值，如果没有声明，cmake默认的是OFF
- 使用：设置好之后我们在命令行去使用的时候，也可以去给他设定值：cmake -DMY-MESSAGE=on ../
- 注意：使用的时候我们应该在值的前面加 "D"
- 这条命令可将MY-MESSAGE的值设置为on，通过这个值我们可以去触发相关的判断

### cmake基础知识
#### 最低版本
- 每个cmake.txt的第一行都会写：cmake_minimum_required(VERSION 3.1)，该命令指定了cmake的最低版本是3.1
- 命令名称cmake_minimum_required不区分大小写
- 设置版本范围：cmake_minimum_required(VERSION 3.1...3.12)，该命令表示支持3.1至3.12之间的版本
- 判断cmake版本
    - if(${CMAKE_VERSION} VERSION_LESS 3.12)
    - cmake_policy(VERSION ${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION})
    - endif()
    - 该命令表示：如果cmake版本小于3.12，则if块将为true，然后将设置为当前cmake版本；如果cmake版本高于3.12，if块为假，cmake_minimum_required将被正确执行
    - 注意：如果需要支持非命令行windows版本，则需要加上else分支，如下：
    - cmake_minimum_required(VERSION 3.1)
    - if(${CMAKE_VERSION} VERSION_LESS 3.12)
    - cmake_policy(VERSION ${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION})
    - else()
    - cmake_policy(VERSION 3.12)
    - endif()

#### 设置生成项目名称

- 使用的命令：project(MyProject)
- 表示我们生成的工程名字叫做：MyProject
- 命令还可以标识项目支持的语言，写法：project (MyProject[C][C++])，不过通常将后面的参数省掉，因为默认支持所有语言
- 使用该指令之后系统会自动创建两个变量：<projectname>_BINARY_DIR：二进制文件保存路径、<projectname>_SOURCE_DIR：源代码路径
- 执行：project(MyProject)，就是定义了一个项目的名称为：MyProject，对应的就会生成两个变量：_BINARY_DIR和_SOURCE_DIR，
但是cmake中其实已经有两个预定义的变量：PROJECT_BINARY_DIR和PROJECT_SOURCE_DIR
- 关于两个变量是否相同，涉及到是内部构建还是外部构建
    - 内部构建
```shell script
cmake ./
make
```    
    - 外部构建
```shell script
mkdir build
cd ./build
cmake ../
make
```     
        
    - 内部构建和外部构建的不同在于：cmake的工作目录不同，内部构建会将cmake生成的中间文件和可执行文件放在和项目同一个目录；外部构建的话，中间
    文件和可执行文件会放在build目录
    - PROJECT_SOURCE_DIR和_SOURCE_DIR无论内部构建还是外部构建，指向的内容是一样的，都指向工程的根目录
    - PROJECT_BINARY_DIR和_BINARY_DIR指向的相同内容，内部构建的时候指向cmakelists.txt文件的目录，外部构建的，指向target编译的目录
    
    
#### 生成可执行文件
- 语法：add_executable(exename srcname)
    - exename: 生成的可执行文件的名字
    - srcname: 依赖的源文件
 
- 该命令指定生成exe的名字以及指出需要依赖的源文件的文件名
- 获取文件路径中的所有源文件
    - 命令：aux_source_directory(<dir> <variable>)
    - 例子：aux_source_directory(. DIR_SRCS)，将当前目录下的源文件名字存放到变量DIR_SRCS里面，如果源文件比较多，直接用DIR_SRCS变量即可
 
- 生成可执行文件：add_executable(Demo ${DIR_SRCS}),将生成的可执行文件命名为：Demo.exe

#### 生成lib库
- 命令：add_library(libname [SHARED|STATIC|MODULE] [EXCLUDE_FROM_ALL] source1 source2 ... sourceN)
    - libname:生成的库文件的名字
    - [SHARED|STATIC|MODULE]:生成库文件的类型（动态库|静态库|模块）
    - [EXCLUDE_FROM_ALL]:有这个参数表示该库不会被默认构建
    - source2 ... sourceN：生成库依赖的源文件，如果源文件比较多，可以使用aux_source_directory命令获取路径下所有源文件
    - 例子：add_library(ALib SHARE alib.cpp)
    
#### 添加头文件目录
- 命令1：target_include_directories(<target> [SYSTEM] [BEFORE] <INTERFACE|PUBLIC|PRIVATE> [items1...] [<INTERFACE|PUBLIC|PRIVATE> [items2...] ...])
当我们添加子项目之后还需要设置一个include路径，例子：target_include_directories(RigelEditor PUBLIC ./include/rgeditor)，表示给RigelEditor这个子项目添加一个库文件的路径

- 命令2：include_directories([AFTER|BEFORE] [SYSTEM] dir1 [dir2...])
    - 参数解析：
    - [AFTER|BEFORE]:指定了要添加路径是添加到原有列表之前还是之后
    - [SYSTEM]：若指定了system参数，则把被包含的路径当做系统包含路径来处理
    - dir1 [dir2...]把这些路径添加到cmakelists及其子目录的cmakelists的头文件包含项目中，相当于g++选项中的-I的参数的作用
    举个例子：include_directories("/opt/MATLAB/R2012a/extern/include")
    - 两条指令的作用都是讲将include的目录添加到目录区别在于include_directories是cmake编译所有目标的目录进行添加，
    target_include_directories是将cmake编译的指定的特定目标的包含目录进行添加
    
#### 添加需要链接的库文件路径
- 命令1：target_link_libraries(<target> [item1 [item2 [...]]] [[debug|optimized|general] <item>] ...)
    - 作用：为给定的目标设置链接时使用的库（设置要链接的库文件的名称）
    - eg：target_link_libraries(MyProject a b.a c.so) // 将若干库文件链接到hello中，target_link_libraries里的库文件的顺序符合gcc/g++链接顺序规则，
    即：被依赖的库放在依赖他的库的后面，如果顺序有错，链接将会报错
    - 关键字：debug对应于调试配置
    - 关键字：optimized对应于所有其他的配置类型
    - 关键字：general对应于所有的配置（该属性是默认值）
    
- 命令2：link_libraries
    - 作用：给当前工程链接需要的库文件（全路径）
    - eg：link_libraries(("/opt/MATLAB/R2012a/bin/glnxa64/libeng.so")//必须添加带名字的全路径)

- 区别：link_libraries和target_link_libraries命令的区别：target_link_libraries可以给工程或者库文件设置其需要链接的库文件，
而且不需要填写全路径，但是link_libraries只能给工程添加依赖的库，而且必须添加全路径

- 添加需要链接的库文件目录
    - 命令：link_directories (添加需要链接的库文件目录)
    - 语法：link_directories(directory1 directory2 ..)
    - 例子：link_directories("/opt/MATLAB/R2012a/bin/glnxa64")
    
- 指令的区别：指令的前缀带target，表示针对某一个目标进行设置，必须指明设置的目标；include_directories是在编译时用，指明.h文件的路径
link_directories是在链接时用的，指明链接库的路径;target_link_libraries是指明链接库的名字，也就是具体谁链接到哪个库。link_libraries不常用，
因为必须指明带文件名全路径

#### 控制目标属性
- 以上的几条命令的区分都是：是否带target前缀，在cmake里面，一个target有自己的属性集，如果我们没有显示的设置这些target的属性的话，
cmake默认是由相关的全局属性来填充target的属性，我们如果需要单独的设置target的属性，需要使用命令：set_target_properties()

- 命令格式
格式：set_target_properties(target1 target2 ... PROPERTIES 属性名称1 值 属性名称2 值 ...)
- 控制编译选项的属性是：COMPILE_FLAGS
- 控制连接选项的属性是：LINK_FLAGS
- 控制输出路径的属性：EXECUTABLE_OUTPUT_PATH (exe的输出路径)、LIBRARY_OUTPUT_PATH (库文件的输出路径)
- 举例：
命令：
set_target_properties(exe PROPERTIES LINK_FLAGS -static LINK_FLAGS_RELEASE -s)

- 这条指令会使得exe这个目标在所有的情况下都采用-static选项，而且在release build的时候-static -s选项。但是这个属性仅仅在exe这个target上面有效

#### 变量和缓存
- 局部变量
    - CMakeLists.txt相当于一个函数，第一个执行的CMakeLists.txt相当于主函数，正常设置的变量不能跨域CMakeLists.txt文件，相当于局部变量只在当前函数域里面的作用一样
    - 设置变量：set(MY_VARIABLE "value")
    - 变量的名称通常大写
    - 访问变量：${MY_VARIABLE}
    
- 缓存变量
    - 缓存变量就是cache变量，相当于全局变量，都是在第一个执行的CMakeLists.txt里面被设置的，不过在子项目的CMakeLists.txt文件里面也是可以修改这个变量的，
    此时会影响父目录的CMakeLists.txt，这些变量用来配置整个工程，配置好之后对整个工程使用
    - 设置缓存变量：set(MY_CACHE_VALUE "cache_value" CACHE INTERNAL "THIS IS MY CACHE VALUE")
    // THIS IS MY CACHE VALUE，这个字符串相当于对变量的描述说明，不能省略，但可以自己随便定义
    
- 环境变量
    - 设置环境变量：set(ENV{variable_name} value)
    - 获取环境变量：$ENV{variable_name}
    
- 内置变量
    - CMake里面包含大量的内置变量，和自定义的变量相同，常用的有以下：
    - CMAKE_C_COMPILER: 指定C编译器
    - CMAKE_CXX_COMPILER：指定C++编译器
    - EXECUTABLE_OUTPUT_PATH：指定可执行文件的存放路径
    - LIBRARY_OUTPUT_PATH：指定库文件的放置路径
    - CMAKE_CURRENT_SOURCE_DIR：当前处理的CMakeLists.txt所在的路径
    - CMAKE_BUILD_TYPE：控制构建的时候是Debug还是Release
    命令：set(CMAKE_BUILD_TYPE Debug)
    - CMAKE_SOURCR_DIR:无论外部构建还是内部构建，都指的是工程的顶层目录
    - CMAKE_BINARY_DIR：内部构建指的是工程顶层目录，外部构建指的是工程发生编译的目录
    - CMAKE_CURRENT_LIST_LINE:输出这个内置变量所在的行
    
- 缓存
    - 缓存就是之前提到的CMakeCache文件，参见：CMake命令行选项的设置
    

### CMake基本控制语法
#### if
##### 基本语法
```shell script
if(expression)
    COMMAND1(ARGS...)
    COMMAND2(ARGS...)
    ...
else
    COMMAND1(ARGS...)
    COMMAND2(ARGS...)
endif (expression)

```

- if(expression),expression不为：空，0，N，NO，OFF，FALSE，NOTFOUND或<var>_NOTFOUND，为真
- IF(not exp)，与上面相反
- if(var1 AND var2)，var1且var2都为真，条件成立
- if(var1 OR var2), var1或var2其中某一个为真，条件成立
- if(COMMAND cmd)，如果cmd确实是命令并可调用，为真
- if(EXISTS dir)如果目录存在，为真
- if(EXISTS file)如果文件存在，为真
- if(file1 IS_NEWER_THAN file2)，当file1比file2新，或file1/file2中有一个不存在时为真，文件名需使用全路径
- if(IS_DIRECTORY dir) 当dir是目录时，为真
- if(DEFINED var)如果变量被定义，为真
- if(string MATCHES regex)当给定变量或字符串能匹配正则表达式regex时，为真

##### 数字表达式
- if(var LESS number),var小于number为真
- if(var GREATER number)，var大于number为真
- if(var EQUAL number)，var等于number为真

##### 字母表顺序比较
- if(var1 STRLESS var2)，var1字母表顺序小于var2为真
- if(var1 STRGREATER var2)，var1字母表顺序大于var2为真
- if(var1 STREQUAL var2)，var1和var2字母顺序相等为真

#### while
##### 语法结构
```shell script
WHILE(condition)
    COMMAND1(ARGS...)
    COMMAND2(ARGS...)
    ...
ENDWHILE(condition)
```

#### foreach
##### 列表循环
- 语法
```shell script
FOREACH(loop_var arg1 arg2...)
    COMMAND1(ARGS...)
    COMMAND2(ARGS...)
...
ENDFOREACH(loop_var)
```
- 例子
```shell script
AUX_SOURCE_DIRECTORY(. SRC_LIST)
FOREACH(F ${SRC_LIST})
    MESSAGE(${F})
ENDFOREACH(F)
```

##### 范围循环
- 语法
```shell script
FOREACH(loop_var RANGE total)
COMMAND1(ARGS...)
COMMAND2(ARGS...)
...
ENDFOREACH(loop_var)
```
##### 范围步进循环
- 语法
```shell script
FOREACH(loop_var RANGE start stop [step])
COMMAND1(ARGS...)
COMMAND2(ARGS...)
...
ENDFOREACH(loop_var)
```

### 构建规范以及构建属性
#### 用于指定构建规则以及程序使用要求的指令：target_include_directories(),target_compile_definitions(),target_compile_options()
#### 指令格式
- target_include_directories(<target> [SYSTEM] [BEFORE] <INTERFACE|PUBLIC|PRIVATE> [items1...] [<INTERFACE|PUBLIC|PRIVATE> [items2...]...])
> include的头文件的查找目录，也就是Gcc的[-Idir...]选项
- target_compile_definitions(<target> <INTERFACE|PUBLIC|PRIVATE> [items1...][<INTERFACE|PUBLIC|PRIVATE> [items2...]...])
> 通过命令行定义的宏变量
- target_compile_options(<target> [BEFORE] <INTERFACE|PUBLIC|PRIVATE> [items1...] [<INTERFACE|PUBLIC|PRIVATE> [items2...]...])
> gcc其他的一些编译选项指定，比如-fPIC

- -fPIC选项说明
说明：-fPIC作用于编译阶段，告诉编译器产生与位置无关代码，则产生的代码中，没有绝对地址，全部使用相对地址，故而代码可以被加载器加载到内存的任意位置，都可以正确执行。
这正是共享库所要求的，共享库被加载时，在内存的位置不是固定的

- -Idir选项说明
说明：在你是用**#include "file"**的时候，gcc/g++会先在当前目录查找你所制定的头文件，如果没有找到，他会到缺省的头文件目录找，
如果使用-I制定了目录，它会先在你所制定的目录查找，然后再按常规的顺序去找

#### 以上的三个命令会生成INCLUDE_DIRECTORIES,COMPILE_DEFINITIONS,COMPILE_OPTIONS变量的值，或者INTERFACE_INCLUDE_DIRECTORIES,INTERFACE_COMPILE_DEFINITIONS,INTERFACE_COMPILE_OPTIONS的值
#### 这三个命令都有三种可选模式，PRIVATE,PUBLIC。INTERFACE.
- PRIVATE模式仅填充不是接口的目标属性；
- INTERFACE模式仅填充接口目标的属性.
- PUBLIC模式填充这两种的目标属性

### 宏和函数
#### 区别
- 函数有范围，而宏没有，如果希望函数设置的变量在函数的外部也可以看见，就需要使用PARENT_SCOPE来修饰，但是函数对于变量的控制会比较好，不会有变量泄漏
- 函数很难将计算结果传出来，使用宏就可以将一些简单的传出来

##### 宏
```shell script
macro([arg1 [arg2 [arg3 ...] ]])
    COMMAND1(ARGS...)
    COMMAND2(ARGS...)
    ...
endmacro()
```
##### 函数
```shell script
function([arg1 [arg2 [arg3 ...] ]])
    COMMAND1(ARGS...)
    COMMAND2(ARGS...)
    ...
endfunction()
```

### 和其他文件的交互
> 暂略

### 如何构建项目
#### 工程目录结构
```shell script
|--- lib
      |--- libA.c
      |--- libB.c
      |--- CMakeLists.txt
|--- include
      |--- includeA.h
      |--- includeB.h
      |--- CMakeLists.txt
|--- main.c
|--- CMakeLists.txt

```
- 第一个CMakeLists.txt
```shell script
# 项目名称
project(main)

# 需要的cmake最低版本
cmake_minium_required(VERSUIB 2.8)

# 将当前目录下的源文件名都赋给DIR_SRC目录
aux_source_directories(. DIR_SRC)

# 添加include目录
include_directories(include)

#生成可执行文件
add_executable(main ${DIR_SRC})

#添加子目录
add_subdirectories(lib)

#将生成的文件与动态库相连
target_link_libraries(main test)
# test是lib目录里生成的

```
- lib目录下的CMakeLists

内容如下：
```shell script
# 将当前的源文件名字都添加到DIR_LIB变量下
aux_source_directory(. DIR_LIB)

# 生成库文件命名为test
add_libraries(test ${DIR_LIB})
```
- include目录的CMakeLists可以为空，因为我们已经将include目录包含在第一层的文件里面

### 在构建时运行的命令
#### find_package：查找链接库
如果编译的过程使用了外部的库，事先并不知道其头文件和链接库的位置，得在编译命令中加上包含外部库的查找路径，cmake中使用find_package方法

##### find_package()命令查找***.cmake的顺序

- 介绍这个命令之前，首先得介绍一个变量：CMAKE_MODULE_PATH
    - 工程比较大的时候，会创建自己的cmake模块，需要告诉cmake这个模块在哪里，cmake就是通过CMAKE_MODULE_PATH这个变量来获取模块路径的
    - 我们使用set来设置模块的路径：set(CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)
- 如果上面的没有找到，就会在../.cmake/packages或者../usr/local/share/中的包目录中查找：<库名字大写>Config.cmake或者<库名字小写>-config.cmake
- 如果找到这个包，则可以通过在工程的顶层目录中的CMakeLists.txt中添加：include_directories(<Name>_INCLUDE_DIRS)来包含库的头文件，使用命令：target_link_libraries(源文件 <NAME>_LIBRARIES)将源文件以及库文件链接起来
- 无论哪种方式，只要找到***.cmake文件，***.cmake里面都会定义下面的这些变量
```shell script
<NAME>_FOUND
<NAME>_INCLUDE_DIRS or <NAME>_INCLUDES
<NAME>_LIBRARIES or <NAME>_LIBRARIES or <NAME>_LIBS
<NAME>_DEFINITIONS
```
- cmake中使用：cmake --help-module-list命令来查看当前cmake中有哪些支持的模块

##### find_package命令参数
```shell script
FIND_PACKAGE(<name> [version] [EXACT] [QUIET] [NO_MODULE] [[REQUIRED|COMPONENTS] [components...]])
```
- version 需要一个版本号，给出这个参数而没有给出EXACT，那就是找到和给出的这个版本号相兼容的就符合条件
- EXACT: 要求版本号必须和version给出的精确匹配
- QUIET: 会禁掉查找的包没有被发现的警告信息，对应于Find<Name>.cmake模块里面的NAME_FIND_QUIETLY变量
- NO_MODULE: 给出该指令后，cmake将直接跳过module模式的查找，直接使用config模式查找
- REQUIRED: 该选项表示如果没有找到需要的包就会停止并且报错
- COMPONENTS: 在REQUIRED选项之后，或者如果没有指定REQUIRED选项但是指定了COMPONENTS选项，在COMPONENTS后面就可以列出一些与包相关部分组件的清单


### 如何添加C++项目中的常用选项
#### 如何激活c++11功能
```shell script
# 语法
target_compile_features(<target> <PRIVATE|PUBLIC|INTERFACE> <feature> [...])
```
- target_compile_features(<project_name> PUBLIC cxx_std_11)
- 参数target必须是由：add_executable或者add_library生成的目标
- 另一种支持c++标准的方法
```shell script
#设置c++标准级别
set(CMAKE_CXX_STANDARD 11)

#告诉CMake使用他
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 确保-std=C++11
set(CMAKE_CXX_EXTENSIONS OFF)
```

#### CMake的过程间优化
- 如果编译器不支持，就会将设置的过程间优化标记为错误，可以使用命令：
check_ipo_supported()来查看
```shell script
#检测编译器是否支持过程间优化
check_ipo_supported(RESULT result)

#如果不支持
if(result)
    #为工程foo设置过程间优化
    set_target_properties(foo PROPERTIES INTERPROCEDURAL_OPTIMIZATION TRUE)
endif()
```












