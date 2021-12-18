---
title: "opengl之四 着色器和uniform Shader and Uniform"
date: 2020-05-10T10:11:54+08:00
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

着色器(Shader)是运行在GPU上的小程序。这些小程序为图形渲染管线的某个特定部分而运行。从基本意义上来说，着色器只是一种把输入转化为输出的程序。着色器也是一种非常独立的程序，因为它们之间不能相互通信；它们之间唯一的沟通只有通过输入和输出。

### GLSL
着色器是使用一种叫GLSL的类C语言写成的

着色器的开头总是要声明版本，接着是输入和输出变量、uniform和main函数。每个着色器的入口点都是main函数，在这个函数中我们处理所有的输入变量，并将结果输出到输出变量中。

一个典型的着色器程序：
```glsl
#version version_number
in type in_variable_name;
in type in_variable_name;

out type out_variable_name;

uniform type uniform_name;

int main()
{
  // 处理输入并进行一些图形操作
  ...
  // 输出处理过的结果到输出变量
  out_variable_name = weird_stuff_we_processed;
}
```
在顶点着色器上，每个输入变量也叫顶点属性，能声明的顶点属性是有上限的，由硬件决定。
opengl至少有16个包含4分量的顶点属性可用，可以通过查询GL_MAX_VERTEX_ATTRIBS来获取具体上限。

```cpp
int nrAttributes;
glGetIntegerv(GL_MAX_VERTEX_ATTRIBS, &nrAttributes);
std::cout << "Maximum nr of vertex attributes supported: " << nrAttributes << std::endl;
```

### 数据类型

glsl中包含C等其他语言大部分的默认基础类型：int、float、double、uint和bool。
glsl也有两种容器，分别是向量（Vector）和矩阵（Matrix）

#### 向量
glsl中的向量是一个包含有1、 2、 3或者4个分量的容器，分量的类型可以是基础类型的任意一个，可以是如下类型：

| 类型 | 含义 |
|:---:|:---:|
|vecn | 包含n个float分量的默认向量|
|bvecn| 包含n个bool分量的向量|
|ivecn| 包含n个int分量的向量|
|uvecn| 包含n个unsigned int分量的向量|
|dvecn| 包含n个double分量的向量|

一个向量的分量可以通过vec.x获取，四个分量分别使用.x、.y、.z和.w来获取他们的第1、 2、 3、4个分量。

glsl允许对颜色使用rgba，或是对纹理坐标使用stpq访问相同的分量。

### 输入与输出

glsl定义了in和out关键字，每个着色器使用这两个关键字设定输入和输出，只要一个输出变量与下一个着色器阶段的输入变量匹配，它就会传递下去。
但在顶点和片段着色器中会有点不同。

顶点着色器应该接收的是一种特殊形式的输入，顶点着色器的输入特殊在，它从顶点数据中直接接收输入。为了定义顶点数据该如何管理，使用location这一元数据指定输入变量，这样才可以在CPU上配置顶点属性。顶点着色器需要为它的输入提供一个额外的layout标识，这样才能把它链接到顶点数据。

> 也可以忽略layout (location = 0)标识符，通过在OpenGL代码中使用glGetAttribLocation查询属性位置值(Location)，但是我更喜欢在着色器中设置它们，这样会更容易理解而且节省你（和OpenGL）的工作量

另一个是片段着色器，它需要一个vec4颜色输出变量，因为片段着色器需要生成一个最终输出的颜色。如果在片段着色器没有定义输出的颜色，opengl会把物体渲染为黑色或者白色。

当从一个着色器向另一个着色器发送数据时，输入和输出的类型和名字一样的时候，opengl就会把两个变量链接到一起，它们之间就能发送数据了。

**顶点着色器**
```glsl
#version 330 core
layout (location = 0) in vec3 aPos; // 位置变量的属性位置值为0

out vec4 vertexColor; // 为片段着色器指定一个颜色输出

void main()
{
    gl_Position = vec4(aPos, 1.0); // 注意我们如何把一个vec3作为vec4的构造器的参数
    vertexColor = vec4(0.5, 0.0, 0.0, 1.0); // 把输出变量设置为暗红色
}
```
片段着色器
```glsl
#version 330 core
out vec4 FragColor;

in vec4 vertexColor; // 从顶点着色器传来的输入变量（名称相同、类型相同）

void main()
{
    FragColor = vertexColor;
}
```

### Uniform
Uniform是一种从CPU中的应用向GPU中的着色器发送数据的方式，但uniform和顶点属性有些不同。

- uniform是全局的，全局意味着uniform变量必须在每个着色器程序对象中都是独一无二的，而且它可以被着色器程序的任意着色器在任意阶段访问
- 无论把uniform值设置成什么，uniform会一直保存它们的数据，直到它们被重置或更新。

uniform使用示例：
```glsl
#version 330 core
out vec4 FragColor;

uniform vec4 ourColor; // 在OpenGL程序代码中设定这个变量

void main()
{
    FragColor = ourColor;
}
```

> 如果你声明了一个uniform却在GLSL代码中没用过，编译器会静默移除这个变量，导致最后编译出的版本中并不会包含它，这可能导致几个非常麻烦的错误，记住这点！

这个uniform目前还是空的，所以我们需要找到着色器中uniform属性的索引值或位置值，然后更新它的值，如：
```cpp
float timeValue = glfwGetTime();
float greenValue = (sin(timeValue)/ 2.0f)+0.5f;
int vertexColorLocation = glGetUniformLocation(shaderProgram, "ourColor");
glUseProgram(shaderProgram);
glUniform4f(vertexColorLocation, 0.0f, greenValue, 0.0f, 1.0f);
```
- 首先，通过glfwGetTime()获取运行的秒数，
- 然后使用sin函数让颜色在0.0到1.0之间改变，
- 最后将结果存储到greenValue里。
- 接着，用glGetUniformLocation查询uniform ourColor的位置值，如果glGetUniformLocation返回-1就代表没有找到这个位置值，
- 最后，通过glUniform4f函数设置uniform值
- 注意，查询uniform地址不要求之前使用过着色器程序，但更新一个uniform之前，必须先使用程序（调用glUseProgram），因为它是在当前激活的着色器程序中设置uniform的

opengl在其核心是一个c库，所以不支持类型重载，在函数参数不同的时候就要为其定义新的函数；glUniform是一个典型例子，这个函数有个特定后缀，标识设定的uniform的类型呢，可能类型如下：

| 后缀 | 含义 |
|:---:|:---:|
| f | 函数需要一个float作为它的值 |
| i | 函数需要一个int作为它的值 |
| ui | 函数需要一个unsigned int 作为它的值 |
| 3f | 函数需要3个float作为它的值 |
| fv | 函数需要一个float向量或数组作为它的值|

现在代码如下：
```cpp
...
while(!glfwWindowShouldClose(window))
{
    // 输入
    processInput(window);

    // 渲染
    // 清除颜色缓冲
    glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    // 记得激活着色器
    glUseProgram(shaderProgram);

    // 更新uniform颜色
    float timeValue = glfwGetTime();
    float greenValue = sin(timeValue) / 2.0f + 0.5f;
    int vertexColorLocation = glGetUniformLocation(shaderProgram, "ourColor");
    glUniform4f(vertexColorLocation, 0.0f, greenValue, 0.0f, 1.0f);

    // 绘制三角形
    glBindVertexArray(VAO);
    glDrawArrays(GL_TRIANGLES, 0, 3);

    // 交换缓冲并查询IO事件
    glfwSwapBuffers(window);
    glfwPollEvents();
}
...
```
可以看到，uniform对于设置一个在渲染迭代中会改变的属性是一个非常有用的工具，它也是一个在程序和着色器间数据交互的很好工具

### 更多属性
算把颜色数据加进顶点数据中。将把颜色数据添加为3个float值至vertices数组。将把三角形的三个角分别指定为红色、绿色和蓝色：
```cpp
float vertices[] = {
    // 位置              // 颜色
     0.5f, -0.5f, 0.0f,  1.0f, 0.0f, 0.0f,   // 右下
    -0.5f, -0.5f, 0.0f,  0.0f, 1.0f, 0.0f,   // 左下
     0.0f,  0.5f, 0.0f,  0.0f, 0.0f, 1.0f    // 顶部
};
```
由于现在更多数据要发送到顶点着色器，需要调整下顶点着色器，使它能够接收颜色值作为一个顶点属性输入。
要注意，用layout标识符来把aColor属性的位置值设置为1：
```glsl
#version 330 core
layout (location = 0) in vec3 aPos;   // 位置变量的属性位置值为 0 
layout (location = 1) in vec3 aColor; // 颜色变量的属性位置值为 1

out vec3 ourColor; // 向片段着色器输出一个颜色

void main()
{
    gl_Position = vec4(aPos, 1.0);
    ourColor = aColor; // 将ourColor设置为我们从顶点数据那里得到的输入颜色
}
```
由于不再使用uniform来传递片段的颜色，现在使用ourColor输出变量，必须改下片段着色器：

```glsl
#version 330 core
out vec4 FragColor;  
in vec3 ourColor;

void main()
{
    FragColor = vec4(ourColor, 1.0);
}
```
因为添加了另一个顶点属性，并且更新了VBO的内存，就必须重新配置顶点属性指针。更新后的VBO内存中的数据现在看起来像这样：

![VBO内存](/image/vertex_attribute_pointer_interleaved.png)

知道了现在使用的布局，就可以使用glVertexAttribPointer函数更新顶点格式，
```cpp
// 位置属性
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)0);
glEnableVertexAttribArray(0);
// 颜色属性
glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(float), (void*)(3* sizeof(float)));
glEnableVertexAttribArray(1);
```
这次配置属性位置值为1的顶点属性。颜色值有3个float那么大，不去标准化这些值。

为获得数据队列中下一个属性值（比如位置向量的下个x分量）必须向右移动6个float，其中3个是位置值，另外3个是颜色值。这使的步长值为6乘以float的字节数（=24字节）。

同样，这次必须指定一个偏移量。对于每个顶点来说，位置顶点属性在前，所以它的偏移量是0。颜色属性紧随位置数据之后，所以偏移量就是3 * sizeof(float)，用字节来计算就是12字节。

### 着色器类

完整的着色器类定义如下:
```cpp
#ifndef __SHADER_H__
#define __SHADER_H__

#include <glad/glad.h>

#include <string>
#include <fstream>
#include <sstream>
#include <iostream>

class Shader
{
public:
    unsigned int ID;
    // constructor generates the shader on the fly
    // ------------------------------------------------------------------------
    Shader(const char* vertexPath, const char* fragmentPath)
    {
        // 1. retrieve the vertex/fragment source code from filePath
        std::string vertexCode;
        std::string fragmentCode;
        std::ifstream vShaderFile;
        std::ifstream fShaderFile;
        // ensure ifstream objects can throw exceptions:
        vShaderFile.exceptions (std::ifstream::failbit | std::ifstream::badbit);
        fShaderFile.exceptions (std::ifstream::failbit | std::ifstream::badbit);
        try 
        {
            // open files
            vShaderFile.open(vertexPath);
            fShaderFile.open(fragmentPath);
            std::stringstream vShaderStream, fShaderStream;
            // read file's buffer contents into streams
            vShaderStream << vShaderFile.rdbuf();
            fShaderStream << fShaderFile.rdbuf();
            // close file handlers
            vShaderFile.close();
            fShaderFile.close();
            // convert stream into string
            vertexCode   = vShaderStream.str();
            fragmentCode = fShaderStream.str();
        }
        catch (std::ifstream::failure& e)
        {
            std::cout << "ERROR::SHADER::FILE_NOT_SUCCESFULLY_READ" << std::endl;
        }
        const char* vShaderCode = vertexCode.c_str();
        const char * fShaderCode = fragmentCode.c_str();
        // 2. compile shaders
        unsigned int vertex, fragment;
        // vertex shader
        vertex = glCreateShader(GL_VERTEX_SHADER);
        glShaderSource(vertex, 1, &vShaderCode, NULL);
        glCompileShader(vertex);
        checkCompileErrors(vertex, "VERTEX");
        // fragment Shader
        fragment = glCreateShader(GL_FRAGMENT_SHADER);
        glShaderSource(fragment, 1, &fShaderCode, NULL);
        glCompileShader(fragment);
        checkCompileErrors(fragment, "FRAGMENT");
        // shader Program
        ID = glCreateProgram();
        glAttachShader(ID, vertex);
        glAttachShader(ID, fragment);
        glLinkProgram(ID);
        checkCompileErrors(ID, "PROGRAM");
        // delete the shaders as they're linked into our program now and no longer necessary
        glDeleteShader(vertex);
        glDeleteShader(fragment);
    }
    // activate the shader
    // ------------------------------------------------------------------------
    void use() 
    { 
        glUseProgram(ID); 
    }
    // utility uniform functions
    // ------------------------------------------------------------------------
    void setBool(const std::string &name, bool value) const
    {         
        glUniform1i(glGetUniformLocation(ID, name.c_str()), (int)value); 
    }
    // ------------------------------------------------------------------------
    void setInt(const std::string &name, int value) const
    { 
        glUniform1i(glGetUniformLocation(ID, name.c_str()), value); 
    }
    // ------------------------------------------------------------------------
    void setFloat(const std::string &name, float value) const
    { 
        glUniform1f(glGetUniformLocation(ID, name.c_str()), value); 
    }

private:
    // utility function for checking shader compilation/linking errors.
    // ------------------------------------------------------------------------
    void checkCompileErrors(unsigned int shader, std::string type)
    {
        int success;
        char infoLog[1024];
        if (type != "PROGRAM")
        {
            glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
            if (!success)
            {
                glGetShaderInfoLog(shader, 1024, NULL, infoLog);
                std::cout << "ERROR::SHADER_COMPILATION_ERROR of type: " << type << "\n" << infoLog << "\n -- --------------------------------------------------- -- " << std::endl;
            }
        }
        else
        {
            glGetProgramiv(shader, GL_LINK_STATUS, &success);
            if (!success)
            {
                glGetProgramInfoLog(shader, 1024, NULL, infoLog);
                std::cout << "ERROR::PROGRAM_LINKING_ERROR of type: " << type << "\n" << infoLog << "\n -- --------------------------------------------------- -- " << std::endl;
            }
        }
    }
};
#endif
```

