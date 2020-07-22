---
title: "Cmake 使用基本教程"
date: 2019-11-23T14:14:43+08:00
keywords: ["cmake"]
categories: ["devtools"]
tags: ["cmake"]
series: [""]
draft: false
toc: true
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

首先创建一个项目
```shell script
mkdir Tutorial
cd Tutorial
touch tutorial.cxx

```
tutorial.cxx内容如下：
```c

```

### 第一步：从最基础开始
最简单的应用是在项目根目录下创建一个CMakeLists.txt文件，内容如下：
```text
# 设置cmake最小要求版本
cmake_minimum_required(VERSION 3.10)

# 设置项目名称
project(Tutorial)

# 添加可执行文件
add_executable(Tutorial tutorial.cxx)

```
CMake支持大写，小写和大小写混合命令，上述示例使用小写方式。

#### 添加版本号和配置头文件
第一个功能cmake_minimum_required是为我们的可执行文件和项目提供版本号。
虽然我们可以仅在源代码中执行此操作，但是使用CMakeLists.txt可提供更大的灵活性
```text
cmake_minimum_required(VERSION 3.10)

# 设置项目版本号
project(Tutorial VERSION 1.0)
```
配置头文件以将版本号传递给源代码
```text
configure_file(TutorialConfig.h.in TutorialConfig.h)
```
由于已配置的文件将被写入二进制树，因此我们必须将该目录添加到路径列表中以搜索包含文件。
将以下行添加到CMakeLists.txt文件的末尾
```text
target_include_directories(Tutorial PUBLIC
                           "${PROJECT_BINARY_DIR}"
                           )
```
在源目录中使用以下内容创建TutorialConfig.h.in
```text
// 配置选项和设置项目配置
#define Tutorial_VERSION_MAJOR @Tutorial_VERSION_MAJOR@
#define Tutorial_VERSION_MINOR @Tutorial_VERSION_MINOR@
```
当CMake配置此头文件时，@Tutorial_VERSION_MAJOR@和@Tutorial_VERSION_MINOR@的值将被替换。 
接下来，修改tutorial.cxx以包括配置的头文件TutorialConfig.h

最后，通过更新tutorial.cxx来打印出版本号
```c
if (argc < 2) {
    // report version
    std::cout << argv[0] << " Version " << Tutorial_VERSION_MAJOR << "."
              << Tutorial_VERSION_MINOR << std::endl;
    std::cout << "Usage: " << argv[0] << " number" << std::endl;
    return 1;
  }
```

#### 指定c++标准
通过在tutorial.cxx中用std :: stod替换atof，将一些C ++ 11功能添加到我们的项目中。同时，删除#include <cstdlib>

```c
const double inputValue = std::stod(argv[1]);
```
我们将需要在CMake代码中明确声明应使用正确的标志。
在CMake中启用对特定C ++标准的支持的最简单方法是使用CMAKE_CXX_STANDARD变量,
如：将CMakeLists.txt文件中的CMAKE_CXX_STANDARD变量设置为11，并将CMAKE_CXX_STANDARD_REQUIRED设置为True

```text
cmake_minimum_required(VERSION 3.10)

# 设置项目名称和版本
project(Tutorial VERSION 1.0)

# 指定c++标准
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED True)
```

#### 构建和测试
运行cmake或cmake-gui以配置项目，
然后使用所选的构建工具进行构建。 
或者切换到根目录下，
然后运行以下命令
```shell script
mkdir step1_build
cd step1_build
cmake ../step1
cmake --build .
```
切换到构建Tutorial的目录（可能是make目录或Debug或Release构建配置子目录），然后运行以下命令
```shell script
Tutorial 4294967296
Tutorial 10
Tutorial
```

### 第二步：添加一个库依赖
将库放入名为MathFunctions的子目录中。该目录已包含头文件MathFunctions.h和源文件mysqrt.cxx。

然后，在子目录MathFunctions目录的CMakeLists.txt文件中添加如下内容：
```text
add_library(MathFunctions mysqrt.cxx)
```

为了利用新库，我们将在顶级CMakeLists.txt文件中添加add_subdirectory调用，以便构建该库。
将新库添加到可执行文件，并将MathFunctions添加为包含目录，以便可以找到mqsqrt.h头文件。
现在，顶层CMakeLists.txt文件的最后添加如下几行：
```text
# 添加MathFunctions库
add_subdirectory(MathFunctions)

# 添加可执行文件
add_executable(Tutorial tutorial.cxx)

# 添加编译链接库
target_link_libraries(Tutorial PUBLIC MathFunctions)

# 将二叉树添加到包含文件的搜索路径
# 这样我们就可以找到TutorialConfig.h
target_include_directories(Tutorial PUBLIC
                          "${PROJECT_BINARY_DIR}"
                          "${PROJECT_SOURCE_DIR}/MathFunctions"
                          )

```

现在让我们将MathFunctions库设为可选。对于较大的项目，这是很常见的情况。
第一步是向顶级CMakeLists.txt文件添加一个选项。
```text
option(USE_MYMATH "Use tutorial provided math implementation" ON)

# 配置头文件以传递某些CMake设置到源代码中
configure_file(TutorialConfig.h.in TutorialConfig.h)
```
此选项将显示在CMake GUI和ccmake中，默认值ON可由用户更改。
此设置将存储在缓存中，以便用户无需在每次在构建目录上运行CMake时都设置该值

下一个更改是使建立和链接MathFunctions库成为条件。
为此，我们将顶级CMakeLists.txt文件的结尾更改为如下所示
```text
if(USE_MYMATH)
  add_subdirectory(MathFunctions)
  list(APPEND EXTRA_LIBS MathFunctions)
  list(APPEND EXTRA_INCLUDES "${PROJECT_SOURCE_DIR}/MathFunctions")
endif()

# 添加可执行文件
add_executable(Tutorial tutorial.cxx)

target_link_libraries(Tutorial PUBLIC ${EXTRA_LIBS})

# 将二叉树添加到包含文件的搜索路径，这样我们就可以找到TutorialConfig.h
target_include_directories(Tutorial PUBLIC
                           "${PROJECT_BINARY_DIR}"
                           ${EXTRA_INCLUDES}
                           )
```
> 请注意，使用变量EXTRA_LIBS来收集所有可选库，以便以后链接到可执行文件中
> 变量EXTRA_INCLUDES类似地用于可选的头文件。这是处理许多可选组件时的经典方法，我们将在下一步中介绍现代方法

首先，在tutorial.cxx中，根据需要添加MathFunctions.h标头
```c
#ifdef USE_MYMATH
#include "MathFunctions.h"
#endif
```
在同一文件中，使USE_MYMATH控制使用哪个平方根函数
```c
#ifdef USE_MYMATH
  const double outputValue = mysqrt(inputValue);
#else
  const double outputValue = sqrt(inputValue);
#endif
```
由于源代码现在需要USE_MYMATH，因此我们可以使用以下行将其添加到TutorialConfig.h.in中
```c
#cmakedefine USE_MYMATH
```
为什么在USE_MYMATH选项之后配置TutorialConfig.h.in如此重要？如果我们将两者倒置会发生什么？
运行cmake或cmake-gui以配置项目，然后使用所选的构建工具进行构建。然后运行构建的Tutorial可执行文件。

使用ccmake或CMake GUI更新USE_MYMATH的值。重新生成并再次运行本教程。 sqrt或mysqrt哪个函数可提供更好的结果。









