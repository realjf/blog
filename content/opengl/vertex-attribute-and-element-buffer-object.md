---
title: "opengl之三 顶点属性与索引缓冲对象 Vertex Attribute and Element Buffer Object"
date: 2020-05-10T08:53:34+08:00
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


### 顶点属性
顶点着色器允许指定任何以顶点属性为形式的输入。
所以，必须在渲染前指定OpenGL该如何解释顶点数据。

顶点缓冲对象（Vertex Buffer Object, VBO）:

![顶点缓冲数据](/image/vertex_attribute_pointer.png)

- 位置数据被存储为32位（4字节）浮点值
- 每个位置包含3个这样的值
- 在这三个值之间没有空隙，这几个值在数组中紧密排列
- 数据中第一个值在缓冲开始的位置

有了这些信息，可以使用glVertexAttribPointer函数告诉opengl该如何解析顶点数据：

```cpp
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
```

- 第一个参数指定要配置的顶点属性。顶点着色器使用layout(location=0)定义了position顶点属性的位置值，它可以把顶点属性值设置为0，因此这里用0传入。
- 第二个参数指定顶点属性的大小。顶点属性是一个vec3，它由三个值组成，所以大小是3。
- 第三个参数指定数据的类型，这里是GL_FLOAT(GLSL中vec*都是由浮点数值组成的)
- 第四个参数定义是否希望数据被标准化，如果设置为GL_TRUE，所有数据都会被映射到0到1之间，这里设置为GL_FALSE。
- 第五个参数定义步长（Stride），指定在连续的顶点属性组之间的间隔。由于下一组位置数据在3个float之后，所以设置步长为3*sizeof(float)，需注意数组是紧密排列的，也可以设置0让opengl决定具体步长是多少。
- 最后一个参数类型是void*，需进行强制类型转换，表示位置数据在缓冲中起始位置的偏移量（offset）。由于位置数据在数组的开头，所以这里是0.

每个顶点属性从一个VBO管理的内存中获得它的数据，而具体是从哪个VBO（程序中可以有多个VBO）获取则是通过在调用glVertexAttribPointer时绑定到GL_ARRAY_BUFFER的VBO决定的。由于在调用glVertexAttribPointer之前绑定的是先前定义的VBO对象，顶点属性0现在会链接到它的顶点数据。


```cpp
glEnableVertexAttribArray(0);
```
使用glEnableVertexAttribArray启用顶点属性，以顶点属性位置值作为参数启用顶点属性，默认是禁用的。

完整的代码如下：
```cpp
// 0. 复制顶点数组到缓冲中供OpenGL使用
glBindBuffer(GL_ARRAY_BUFFER, VBO);
glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
// 1. 设置顶点属性指针
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
glEnableVertexAttribArray(0);
// 2. 当渲染一个物体时要使用着色器程序
glUseProgram(shaderProgram);
// 3. 绘制物体
...
```

### 顶点数组对象
顶点数组对象(Vertex Array Object, VAO)，可以像顶点缓冲对象那样被绑定，任何随后的顶点属性调用都会储存在这个VAO中。这样的好处就是，当配置顶点属性指针时，你只需要将那些调用执行一次，之后再绘制物体的时候只需要绑定相应的VAO就行了。

在不同顶点数据和属性配置之间切换，只需要绑定不同的VAO就行了。

> OpenGL的核心模式要求使用VAO，所以它知道该如何处理的顶点输入。如果绑定VAO失败，OpenGL会拒绝绘制任何东西。

一个顶点数组对象会存储以下内容

- glEnableVertexAttribArray和glDisableVertexAttribArray的调用。
- 通过glVertexAttribPointer设置的顶点属性配置。
- 通过glVertexAttribPointer调用与顶点属性关联的顶点缓冲对象。

![顶点数组对象](/image/vertex_array_objects.png)

创建一个VAO
```cpp
unsigned int VAO;
glGenVertexArrays(1, &VAO);
```

使用glBindVertexArray绑定VAO。当打算绘制一个物体的时候，只要在绘制物体前简单地把VAO绑定到希望使用的设定上就行了。
```cpp
// 1. 绑定VAO
glBindVertexArray(VAO);
// 2. 把顶点数组复制到缓冲中供OpenGL使用
glBindBuffer(GL_ARRAY_BUFFER, VBO);
glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
// 3. 设置顶点属性指针
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
glEnableVertexAttribArray(0);
...
// 4. 绘制物体前启用shader，绑定VAO
glUseProgram(shaderProgram);
glBindVertexArray(VAO);
// 5. 画三角形
glDrawArrays(GL_TRIANGLES, 0, 3);
...
```
glDrawArrays函数：

- 第一个参数是打算绘制的OpenGL图元的类型。
- 第二个参数指定了顶点数组的起始索引，这里填0。
- 最后一个参数指定打算绘制多少个顶点，这里是3



### 索引缓冲对象

索引缓冲对象(Element Buffer Object，EBO，也叫Index Buffer Object，IBO)。

假设绘制一个矩形，通过绘制两个三角形来组成一个矩形。矩形的顶点集合如下：
```cpp
float vertices[] = {
    // 第一个三角形
    0.5f, 0.5f, 0.0f,   // 右上角
    0.5f, -0.5f, 0.0f,  // 右下角
    -0.5f, 0.5f, 0.0f,  // 左上角
    // 第二个三角形
    0.5f, -0.5f, 0.0f,  // 右下角
    -0.5f, -0.5f, 0.0f, // 左下角
    -0.5f, 0.5f, 0.0f   // 左上角
};
```
可以看到，有几个顶点叠加了。指定了右下角和左上角两次！一个矩形只有4个而不是6个顶点，这样就产生50%的额外开销。
更好的解决方案是只储存不同的顶点，并设定绘制这些顶点的顺序。这样只要储存4个顶点就能绘制矩形了，之后只要指定绘制的顺序就行了。

很幸运，索引缓冲对象的工作方式正是这样的。和顶点缓冲对象一样，EBO也是一个缓冲，它专门储存索引，OpenGL调用这些顶点的索引来决定该绘制哪个顶点。

首先，先要定义（不重复的）顶点，和绘制出矩形所需的索引：
```cpp
float vertices[] = {
    0.5f, 0.5f, 0.0f,   // 右上角
    0.5f, -0.5f, 0.0f,  // 右下角
    -0.5f, -0.5f, 0.0f, // 左下角
    -0.5f, 0.5f, 0.0f   // 左上角
};

unsigned int indices[] = { // 注意索引从0开始! 
    0, 1, 3, // 第一个三角形
    1, 2, 3  // 第二个三角形
};
```
下一步创建索引缓冲对象
```cpp
unsigned int EBO;
glGenBuffers(1, &EBO);
```
与VBO类似，先绑定EBO然后用glBufferData把索引复制到缓冲里

把这些函数调用放在绑定和解绑函数调用之间，把缓冲的类型定义为GL_ELEMENT_ARRAY_BUFFER。
```cpp
glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
```

用glDrawElements来替换glDrawArrays函数，来指明从索引缓冲渲染:
```cpp
glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
```
- 第一个参数指定了绘制的模式
- 第二个参数是打算绘制顶点的个数
- 第三个参数是索引的类型，这里是GL_UNSIGNED_INT
- 最后一个参数可以指定EBO中的偏移量（或者传递一个索引数组，但是这是当你不在使用索引缓冲对象的时候），这里填0

必须在每次要用索引渲染一个物体时绑定相应的EBO，这还是有点麻烦。不过顶点数组对象同样可以保存索引缓冲对象的绑定状态。VAO绑定时正在绑定的索引缓冲对象会被保存为VAO的元素缓冲对象。绑定VAO的同时也会自动绑定EBO。

![索引缓冲对象](/image/vertex_array_objects_ebo.png)

> 当目标是GL_ELEMENT_ARRAY_BUFFER的时候，VAO会储存glBindBuffer的函数调用。这也意味着它也会储存解绑调用，所以确保你没有在解绑VAO之前解绑索引数组缓冲，否则它就没有这个EBO配置了。

代码如下：
```cpp
...
// 1. 绑定顶点数组对象
glBindVertexArray(VAO);
// 2. 把我们的顶点数组复制到一个顶点缓冲中，供OpenGL使用
glBindBuffer(GL_ARRAY_BUFFER, VBO);
glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
// 3. 复制我们的索引数组到一个索引缓冲中，供OpenGL使用
glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
// 4. 设定顶点属性指针
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
glEnableVertexAttribArray(0);

...

// ..:: 绘制代码（渲染循环中） :: ..
glUseProgram(shaderProgram);
glBindVertexArray(VAO);
glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0)
glBindVertexArray(0);
...
```

#### 线框模式
要想用线框模式绘制你的三角形，你可以通过glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)函数配置OpenGL如何绘制图元。

- 第一个参数表示打算将其应用到所有的三角形的正面和背面，
- 第二个参数告诉用线来绘制。之后的绘制调用会一直以线框模式绘制三角形，直到用glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)将其设置回默认模式。

### 完整代码
main.cpp内容如下：

```cpp
#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <iostream>

void framebuffer_size_callback(GLFWwindow* window, int width, int height);
void processInput(GLFWwindow *window);

const unsigned int SCR_WIDTH = 800;
const unsigned int SCR_HEIGHT = 600;

const char *vertexShaderSource = "#version 330 core\n"
    "layout (location = 0) in vec3 aPos;\n"
    "void main()\n"
    "{\n"
    "   gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);\n"
    "}\0";
const char *fragmentShaderSource = "#version 330 core\n"
    "out vec4 FragColor;\n"
    "void main()\n"
    "{\n"
    "   FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);\n"
    "}\n\0";

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
        exit(-1);
    }  


    // 顶点着色器
    unsigned int vertexShader;
    // 创建着色器
    vertexShader = glCreateShader(GL_VERTEX_SHADER);
    // 将着色器源码附加到着色器对象上，然后编译它
    glShaderSource(vertexShader, 1, &vertexShaderSource, NULL);
    glCompileShader(vertexShader);

    // check for shader compile errors
    int success;
    char infoLog[512];
    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &success);
    if (!success)
    {
        glGetShaderInfoLog(vertexShader, 512, NULL, infoLog);
        std::cout << "ERROR::SHADER::VERTEX::COMPILATION_FAILED\n" << infoLog << std::endl;
    }

    // 片段着色器
    unsigned int fragmentShader;
    fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentShaderSource, NULL);
    glShaderSource(fragmentShader, 1, &fragmentShaderSource, NULL);
    glCompileShader(fragmentShader);

    // check for shader compile errors
    glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &success);
    if (!success)
    {
        glGetShaderInfoLog(fragmentShader, 512, NULL, infoLog);
        std::cout << "ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n" << infoLog << std::endl;
    }

    // 着色器程序
    unsigned int shaderProgram;
    // 创建一个程序
    shaderProgram = glCreateProgram();
    // 将之前编译的着色器附加到程序对象上，然后用glLinkProgram链接它们
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    glLinkProgram(shaderProgram);

    // check for linking errors
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, &success);
    if (!success) {
        glGetProgramInfoLog(shaderProgram, 512, NULL, infoLog);
        std::cout << "ERROR::SHADER::PROGRAM::LINKING_FAILED\n" << infoLog << std::endl;
    }

    // 在把着色器对象链接到程序对象以后，记得删除着色器对象，我们不再需要它们了
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);

    // 调用glUseProgram函数，用刚创建的程序对象作为它的参数，以激活这个程序对象
    glUseProgram(shaderProgram);
    
    // 索引缓冲对象
    float vertices[] = {
        0.5f, 0.5f, 0.0f,   // 右上角
        0.5f, -0.5f, 0.0f,  // 右下角
        -0.5f, -0.5f, 0.0f, // 左下角
        -0.5f, 0.5f, 0.0f   // 左上角
    };

    unsigned int indices[] = { // 注意索引从0开始! 
        0, 1, 3, // 第一个三角形
        1, 2, 3  // 第二个三角形
    };

    // 顶点输入
    unsigned int VBO, VAO, EBO;
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &EBO);
    glGenVertexArrays(1, &VAO);

    glBindVertexArray(VAO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    // 复制顶点数组到缓冲中供OpenGL使用
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    // 将索引复制到缓冲里
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);

    // 告诉OpenGL该如何解析顶点数据
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
    // 以顶点属性位置值作为参数，启用顶点属性，顶点属性默认是禁用的
    glEnableVertexAttribArray(0);
    // 已经调用glVertexAttribPointer将VBO注册为顶点属性的绑定顶点缓冲区对象，因此此后我们可以安全地解除绑定
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    // 之后，您可以取消绑定VAO，这样其他VAO调用就不会意外修改此VAO，
    // 因为修改其他VAO无论如何都需要调用glBindVertexArray，所以在不是直接需要情况下，我们通常不解绑VAO
    glBindVertexArray(0);


    while (!glfwWindowShouldClose(window))
    {
        // input
        // -----
        processInput(window);

        // render
        // ------
        glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);  


         // 画三角形
        glUseProgram(shaderProgram);
        glBindVertexArray(VAO); // seeing as we only have a single VAO there's no need to bind it every time, but we'll do so to keep things a bit more organized
        // glDrawArrays(GL_TRIANGLES, 0, 3);   

        // 画矩形
        
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);

        // glfw: swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
        // -------------------------------------------------------------------------------
        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    // 取消分配的所有资源
    glDeleteVertexArrays(1, &VAO);
    glDeleteBuffers(1, &VBO);
    glDeleteProgram(shaderProgram);

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
CMakeLists.txt内容如下：
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
include_directories( ${opengl_INCLUDE} )

set(COMMON_LIBS glfw X11 GL GLEW Xrandr Xi Xxf86vm Xcursor Xinerama pthread GLU dl GLU)

set(SOURCE_FILES main.cpp glad.c)
add_executable(example ${SOURCE_FILES})


target_link_libraries(example
    PUBLIC 
    ${COMMON_LIBS})
```
把glad和glfw下载到deps目录下，复制glad/src/glad.c到main.cpp目录下，然后运行如下命令进行构建
```sh
mkdir build
cd build
cmake ..
make
```






