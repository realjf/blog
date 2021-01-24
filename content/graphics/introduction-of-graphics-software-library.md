---
title: "图形软件库介绍 Introduction of Graphics Software Library"
date: 2021-01-24T10:25:08+08:00
keywords: ["graphics"]
categories: ["graphics"]
tags: ["graphics"]
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

## 图形库包括：OpenGL、OpenCV、OpenCL、OpenGL ES、OpenAL、WebGL、OpenMP、DirectX

### OpenGL
（全写Open Graphics Library），工业标准，计算机图形库，是定义了一个跨编程语言、跨平台的编程接口规格的专业的图形程序接口。它用于三维图像（二维的亦可），是一个功能强大，调用方便的底层图形库。

- OpenGL的前身是SGI公司为其图形工作站开发的IRIS GL。IRIS GL是一个工业标准的3D图形软件接口，SGI公司便在IRIS GL的基础上开发了OpenGL
- OpenGL中的gl库是核心库，glu是实用库，glut是实用工具库；gl是核心，glu是对gl的部分封装，glut是OpenGL的跨平台工具库
- OpenGL分为：核心模式（不支持以前版本）和兼容模式（支持以前版本的函数）
- OpenGL 就是 GPU 驱动 的一套标准接口
- GLSL：Opengl着色器语言，在GPU上执行的可编程渲染管线，区别于传统的固定管线，文件扩展名*.glsl

### OpenCV
全称是：Open Source Computer Vision Library。OpenCV是一个开源发行的跨平台计算机视觉库，可以运行在Linux、Windows和Mac OS操作系统上。它轻量级而且高效——由一系列 C 函数和少量 C++ 类构成，同时提供了Python、Ruby、MATLAB等语言的接口，实现了图像处理和计算机视觉方面的很多通用算法。

- OpenCV用C++语言编写，它的主要接口也是C++语言，但是依然保留了大量的C语言接口。该库也有大量的Python, Java and MATLAB/OCTAVE (版本2.5)的接口。这些语言的API接口函数可以通过在线文档获得。如今也提供对于C#,Ch, Ruby的支持


应用领域：
- 1、人机互动；
- 2、物体识别；
- 3、图像分割；
- 4、人脸识别；
- 5、动作识别；
- 6、运动跟踪；
- 7、机器人；
- 8、运动分析；
- 9、机器视觉；
- 10、结构分析；
- 11、汽车安全驾驶；




### OpenCL
OpenCL全称Open Computing Language，是第一个面向异构系统通用目的并行编程的开放式、免费标准，也是一个统一的编程环境，便于软件开发人员为高性能计算服务器、桌面计算系统、手持设备编写高效轻便的代码，而且广泛适用于多核心处理器(CPU)、图形处理器(GPU)、Cell类型架构以及数字信号处理器(DSP)等其他并行处理器，在游戏、娱乐、科研、医疗等各种领域都有广阔的发展前景。

#### OpenCL框架组成

本文主要讨论OpenCL框架，其组成可划分为以下三个部分：

- OpenCL平台API：平台API定义了宿主机程序发现OpenCL设备所用的函数以及这些函数的功能，另外还定义了为OpenCL应用创建上下文的函数。
- OpenCL运行时API：这个API管理上下文来创建命令队列以及运行时发生的其他操作。例如，将命令提交到命令队列的函数就来自OpenCL运行时API。
- OpenCL编程语言：这是用来编写内核代码的编程语言。它基于ISO C99标准的一个扩展子集，因此通常称为OpenCL C编程语言。

### OpenGL ES
OpenGL ES 为嵌入式设备 GPU 驱动（如手机）的标准接口，OpenGL ES 全称：OpenGL for Embedded Systems。它是基于OpenGL API设计的，是OpenGL 三维图形API的子集，针对手机、PDA和游戏主机等嵌入式设备而设计。该API由Khronos集团定义、推广，Khronos是一个图形软硬件行业协会。

- OpenGL ES现在主要有两个版本：OpenGL 1.x 针对固定管线硬件，OpenGL 2.x针对可编程管线硬件。
- OpenGL ES 是从 OpenGL 裁剪定制而来的，去除了 glBegin/glEnd，四边形（GL_QUADS）、多边形（GL_POLYGONS）等复杂图元等许多非绝对必要的特性。经过多年发展，现在主要有两个版本，OpenGL ES 1.x 针对固定管线硬件的，OpenGL ES 2.x 针对可编程管线硬件。OpenGL ES 1.0 是以 OpenGL 1.3 规范为基础的，OpenGL ES 1.1 是以 OpenGL 1.5 规范为基础的，它们分别又支持 common 和 common lite 两种profile。lite profile只支持定点定点实数，而common profile既支持定点数又支持浮点数。 OpenGL ES 2.0 则是参照 OpenGL 2.0 规范定义的，common profile发布于2005-8，引入了对可编程管线的支持


### OpenAL
（Open Audio Library）是自由软件界的跨平台音效API。它设计给多通道三维位置音效的特效表现。其 API 风格模仿自OpenGL。

- OpenAL 主要的功能是在来源物体、音效缓冲和收听者中编码。
- OpenAL是一个开源的音频后处理工具包，可以添加各种音效，修改声源空间位置等等。
- 不同于 OpenGL 规格，OpenAL 规格包含两个API分支；以实际 OpenAL 函式组成的核心，和 ALC API，ALC 用于管理表现内容、资源使用情况，并将跨平台风格封在其中。还有“ALUT”程式库，提供高阶“易用”的函式，其定位相当于 OpenGL 的 GLUT。


### WebGL
WebGL是一种3D绘图标准，这种绘图技巧标准允许把JavaScript和OpenGL ES 2.0结合在一起，为HTML5 Canvas供给硬件3D加速渲染。WebGL技巧标准免去了开发网页专用渲染插件的麻烦，可被用于创建具有繁杂3D结构的网站页面，甚至可以用来设计3D网页游戏等。WebGL开启了网页3D渲染的新时代，它允许在canvas中直接渲染3D的内容，而不借助任何插件。

### OpenMP
全写 Open Multi-Processing开源的并行编程，是由OpenMP Architecture Review Board牵头提出的，并已被广泛接受的，用于共享内存并行系统的多处理器程序设计的一套指导性的编译处理方案(Compiler Directive)。OpenMP支持的编程语言包括C语言、C++和Fortran；而支持OpenMp的编译器包括Sun Compiler，GNU Compiler和Intel Compiler等。OpenMp提供了对并行算法的高层的抽象描述，程序员通过在源代码中加入专用的pragma来指明自己的意图，由此编译器可以自动将程序进行并行化，并在必要之处加入同步互斥以及通信。当选择忽略这些pragma，或者编译器不支持OpenMP时，程序又可退化为通常的程序(一般为串行)，代码仍然可以正常运作，只是不能利用多线程来加速程序执行。

OpenMP和OpenCL都是用于高性能计算机，但是关键点不一样，前者主要是基于CPU的并行，后者主攻是异构系统中GPU并行

### DirectX
DirectX（Direct eXtension，简称DX）是由微软公司创建的多媒体编程接口，是一种应用程序接口（API）。DirectX可以让以windows为平台的游戏或多媒体程序获得更高的执行效率，加强3D图形和声音效果，并提供设计人员一个共同的硬件驱动标准，让游戏开发者不必为每一品牌的硬件来写不同的驱动程序，也降低用户安装及设置硬件的复杂度。DirectX已被广泛使用于Microsoft Windows、Microsoft XBOX、Microsoft XBOX 360和Microsoft XBOX ONE电子游戏开发。




