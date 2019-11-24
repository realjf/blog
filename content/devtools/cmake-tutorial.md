---
title: "Cmake Tutorial"
date: 2019-11-23T14:14:43+08:00
keywords: ["cmake"]
categories: ["devtools"]
tags: ["cmake"]
series: [""]
draft: true
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

### 第一步：从最基础开始
最简单的应用是在项目根目录下创建一个CMakeLists.txt文件，内容如下：
```text
# 设置cmake最小要求版本
cmake_minimum_required(VERSION 3.10)

# 设置项目名称
project(Tutorial)

# 添加可执行文件
add_executableTutorial

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





