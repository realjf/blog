---
title: "opengl之五 纹理 Textures"
date: 2021-05-10T11:30:39+08:00
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

### 纹理

纹理是一个2D图片（甚至也有1D和3D的纹理），它可以用来添加物体的细节；你可以想象纹理是一张绘有砖块的纸，无缝折叠贴合到你的3D的房子上，这样你的房子看起来就像有砖墙外表了。因为可以在一张图片上插入非常多的细节，这样就可以让物体非常精细而不用指定额外的顶点。


为了能够把纹理映射(Map)到三角形上，需要指定三角形的每个顶点各自对应纹理的哪个部分。这样每个顶点就会关联着一个纹理坐标(Texture Coordinate)，用来标明该从纹理图像的哪个部分采样。之后在图形的其它片段上进行片段插值(Fragment Interpolation)。

纹理坐标在x和y轴上，范围为0到1之间（注意使用的是2D纹理图像）。使用纹理坐标获取纹理颜色叫做采样(Sampling)。纹理坐标起始于(0, 0)，也就是纹理图片的左下角，终始于(1, 1)，即纹理图片的右上角。下面的图片展示了如何把纹理坐标映射到三角形上的。

![纹理坐标](/image/tex_coords.png)

为三角形指定了3个纹理坐标点。如上图所示，三角形的左下角对应纹理的左下角，因此把三角形左下角顶点的纹理坐标设置为(0, 0)；三角形的上顶点对应于图片的上中位置所以把它的纹理坐标设置为(0.5, 1.0)；同理右下方的顶点设置为(1, 0)。只要给顶点着色器传递这三个纹理坐标就行了，接下来它们会被传片段着色器中，它会为每个片段进行纹理坐标的插值。

纹理坐标看起来像是这样的：
```cpp
float texCoords[] = {
    0.0f, 0.0f, // 左下角
    1.0f, 0.0f, // 右下角
    0.5f, 1.0f // 上中
};
```

### 纹理环绕方式
纹理坐标的范围通常是从(0, 0)到(1, 1)，如果把纹理坐标设置在范围之外，OpenGL默认的行为是重复这个纹理图像（基本上忽略浮点纹理坐标的整数部分），但OpenGL提供了更多的选择：

| 环绕方式 | 描述 |
|:---:|:---:|
| GL_REPEAT | 对纹理的默认行为，重复纹理图像|
| GL_MIRRORED_REPEAT | 和GL_REPEAT一样，但每次重复图片是镜像放置的|
| GL_CLAMP_TO_EDGE | 纹理坐标会被约束在0到1之间，超出的部分会重复纹理坐标的边缘，产生一种边缘被拉伸的效果 |
| GL_CLAMP_TO_BORDER | 超出的坐标为用户指定的边缘颜色 |

当纹理超出范围时的效果：

![纹理效果](/image/texture_wrapping.png)

前面提到的每个选项都可以使用glTexParameter*函数对单独的一个坐标轴设置（s、t如果是使用3D纹理那么还有一个r），他们和x、y、z是等价的。
```cpp
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_MIRRORED_REPEAT);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_MIRRORED_REPEAT);
```
- 第一个参数指定了纹理目标；使用的是2D纹理，因此纹理目标是GL_TEXTURE_2D。
- 第二个参数需要指定设置的选项与应用的纹理轴。打算配置的是WRAP选项，并且指定S和T轴。
- 最后一个参数需要传递一个环绕方式(Wrapping)

如果选择GL_CLAMP_TO_BORDER选项，还需要指定一个边缘的颜色。这需要使用glTexParameter函数的fv后缀形式，用GL_TEXTURE_BORDER_COLOR作为它的选项，并且传递一个float数组作为边缘的颜色值：

```cpp
float borderColor[] = { 1.0f, 1.0f, 0.0f, 1.0f };
glTexParameterfv(GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR, borderColor);
```

### 纹理过滤
纹理坐标不依赖于分辨率(Resolution)，它可以是任意浮点值，所以OpenGL需要知道怎样将纹理像素(Texture Pixel，也叫Texel，译注1)映射到纹理坐标。当你有一个很大的物体但是纹理的分辨率很低的时候这就变得很重要了。你可能已经猜到了，OpenGL也有对于纹理过滤(Texture Filtering)的选项。纹理过滤有很多个选项，但是现在只讨论最重要的两种：GL_NEAREST和GL_LINEAR。

GL_NEAREST（也叫邻近过滤，Nearest Neighbor Filtering）是OpenGL默认的纹理过滤方式。当设置为GL_NEAREST的时候，OpenGL会选择中心点最接近纹理坐标的那个像素。下图中你可以看到四个像素，加号代表纹理坐标。左上角那个纹理像素的中心距离纹理坐标最近，所以它会被选择为样本颜色

![nearest](/image/filter_nearest.png)

GL_LINEAR（也叫线性过滤，(Bi)linear Filtering）它会基于纹理坐标附近的纹理像素，计算出一个插值，近似出这些纹理像素之间的颜色。一个纹理像素的中心距离纹理坐标越近，那么这个纹理像素的颜色对最终的样本颜色的贡献越大。下图中你可以看到返回的颜色是邻近像素的混合色：

![linear](/image/filter_linear.png)

那么这两种纹理过滤方式有怎样的视觉效果呢？让我们看看在一个很大的物体上应用一张低分辨率的纹理会发生什么吧（纹理被放大了，每个纹理像素都能看到）：

![纹理过滤效果](/image/texture_filteriing.png)

GL_NEAREST产生了颗粒状的图案，能够清晰看到组成纹理的像素，而GL_LINEAR能够产生更平滑的图案，很难看出单个的纹理像素。GL_LINEAR可以产生更真实的输出，但有些开发者更喜欢8-bit风格，所以他们会用GL_NEAREST选项。

当进行放大(Magnify)和缩小(Minify)操作的时候可以设置纹理过滤的选项

使用glTexParameter*函数为放大和缩小指定过滤方式

```cpp
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
```
#### 多级渐远纹理
OpenGL使用一种叫做多级渐远纹理来处理远处的物体纹理。

简单来说就是一系列的纹理图像，后一个纹理图像是前一个的二分之一。多级渐远纹理背后的理念很简单：距观察者的距离超过一定的阈值，OpenGL会使用不同的多级渐远纹理，即最适合物体的距离的那个。由于距离远，解析度不高也不会被用户注意到。同时，多级渐远纹理另一加分之处是它的性能非常好。

手工为每个纹理图像创建一系列多级渐远纹理很麻烦，OpenGL有一个glGenerateMipmaps函数，在创建完一个纹理后调用它OpenGL就会承担接下来的所有工作了

切换多级渐远纹理级别时你也可以在两个不同多级渐远纹理级别之间使用NEAREST和LINEAR过滤。为了指定不同多级渐远纹理级别之间的过滤方式，你可以使用下面四个选项中的一个代替原有的过滤方式：

| 过滤方式 | 描述 |
|:---:|:---:|
| GL_NEAREST_MIPMAP_NEAREST	| 使用最邻近的多级渐远纹理来匹配像素大小，并使用邻近插值进行纹理采样|
| GL_LINEAR_MIPMAP_NEAREST	| 使用最邻近的多级渐远纹理级别，并使用线性插值进行采样|
| GL_NEAREST_MIPMAP_LINEAR	| 在两个最匹配像素大小的多级渐远纹理之间进行线性插值，使用邻近插值进行采样|
| GL_LINEAR_MIPMAP_LINEAR	| 在两个邻近的多级渐远纹理之间使用线性插值，并使用线性插值进行采样|

可以使用glTexParameteri将过滤方式设置为前面四种提到的方法之一：
```cpp
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
```

**一个常见的错误是，将放大过滤的选项设置为多级渐远纹理过滤选项之一**。
这样没有任何效果，因为多级渐远纹理主要是使用在纹理被缩小的情况下的：纹理放大不会使用多级渐远纹理，为放大过滤设置多级渐远纹理的选项会产生一个GL_INVALID_ENUM错误代码。



### 加载与创建纹理

使用纹理之前要做的第一件事是把它们加载到应用中。纹理图像可能被储存为各种各样的格式，每种都有自己的数据结构和排列，使用一个支持多种流行格式的图像加载库来处理是一种很好的选择。

#### stb_image.h

stb_image.h是[Sean Barrett](https://github.com/nothings)的一个非常流行的单头文件图像加载库，它能够加载大部分流行的文件格式，并且能够很简单得整合到你的工程之中。stb_image.h可以在[这里](https://github.com/nothings/stb/blob/master/stb_image.h)下载

一个新的C++文件，输入以下代码：
```cpp
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
```
通过定义STB_IMAGE_IMPLEMENTATION，预处理器会修改头文件，让其只包含相关的函数定义源码，等于是将这个头文件变为一个 .cpp 文件了。现在只需要在你的程序中包含stb_image.h并编译就可以了。

要使用stb_image.h加载图片，需要使用它的stbi_load函数：
```cpp
int width, height, nrChannels;
unsigned char *data = stbi_load("container.jpg", &width, &height, &nrChannels, 0);
```
- 第一个参数是图像文件路径
- 第二个参数是图像宽度
- 第三个参数是图像高度
- 第四个参数是图像颜色通道的个数

### 生成纹理
创建一个纹理
```cpp
unsigned int texture;
glGenTextures(1, &texture);
```
通过绑定，让之后任何的纹理指令都可以配置当前绑定的纹理：
```cpp
glBindTexture(GL_TEXTURE_2D, texture);
```
使用glTexImage2D来载入图片生成一个纹理：
```cpp
glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
glGenerateMipmap(GL_TEXTURE_2D);
```
- 第一个参数指定了纹理目标(Target)。设置为GL_TEXTURE_2D意味着会生成与当前绑定的纹理对象在同一个目标上的纹理（任何绑定到GL_TEXTURE_1D和GL_TEXTURE_3D的纹理不会受到影响）。
- 第二个参数为纹理指定多级渐远纹理的级别，如果希望单独手动设置每个多级渐远纹理的级别的话。这里填0，也就是基本级别。
- 第三个参数告诉OpenGL把纹理储存为何种格式。我们的图像只有RGB值，因此也把纹理储存为RGB值。
- 第四个和第五个参数设置最终的纹理的宽度和高度。之前加载图像的时候储存了它们，所以使用对应的变量。
- 下个参数应该总是被设为0（历史遗留的问题）。
- 第七第八个参数定义了源图的格式和数据类型。使用RGB值加载这个图像，并把它们储存为char(byte)数组，将会传入对应值。
- 最后一个参数是真正的图像数据。

当调用glTexImage2D时，当前绑定的纹理对象就会被附加上纹理图像。然而，目前只有基本级别(Base-level)的纹理图像被加载了，如果要使用多级渐远纹理，我们必须手动设置所有不同的图像（不断递增第二个参数）。或者，直接在生成纹理之后调用glGenerateMipmap。这会为当前绑定的纹理自动生成所有需要的多级渐远纹理。


生成了纹理和相应的多级渐远纹理后，释放图像的内存
```cpp
stbi_image_free(data);
```
现在，生成纹理的代码过程如下：
```cpp
unsigned int texture;
glGenTextures(1, &texture);
glBindTexture(GL_TEXTURE_2D, texture);
// 为当前绑定的纹理对象设置环绕、过滤方式
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);   
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
// 加载并生成纹理
int width, height, nrChannels;
unsigned char *data = stbi_load("container.jpg", &width, &height, &nrChannels, 0);
if (data)
{
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
    glGenerateMipmap(GL_TEXTURE_2D);
}
else
{
    std::cout << "Failed to load texture" << std::endl;
}
stbi_image_free(data);
```

### 应用纹理
需要告知OpenGL如何采样纹理，所以必须使用纹理坐标更新顶点数据：
```cpp
float vertices[] = {
//     ---- 位置 ----       ---- 颜色 ----     - 纹理坐标 -
     0.5f,  0.5f, 0.0f,   1.0f, 0.0f, 0.0f,   1.0f, 1.0f,   // 右上
     0.5f, -0.5f, 0.0f,   0.0f, 1.0f, 0.0f,   1.0f, 0.0f,   // 右下
    -0.5f, -0.5f, 0.0f,   0.0f, 0.0f, 1.0f,   0.0f, 0.0f,   // 左下
    -0.5f,  0.5f, 0.0f,   1.0f, 1.0f, 0.0f,   0.0f, 1.0f    // 左上
};
```
现在，必须告诉opengl新的顶点格式如何解析：
```cpp
glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 8 * sizeof(float), (void*)(6 * sizeof(float)));
glEnableVertexAttribArray(2);
```

接着，调整顶点着色器使其能够接收顶点坐标为一个顶点属性，并把坐标传给片段着色器：
```glsl
#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColor;
layout (location = 2) in vec2 aTexCoord;

out vec3 ourColor;
out vec2 TexCoord;

void main()
{
    gl_Position = vec4(aPos, 1.0);
    ourColor = aColor;
    TexCoord = aTexCoord;
}
```
片段着色器也应该能访问纹理对象，GLSL有一个供纹理对象使用的内建数据类型，叫做采样器(Sampler)，它以纹理类型作为后缀，比如sampler1D、sampler3D，或sampler2D。可以简单声明一个uniform sampler2D把一个纹理添加到片段着色器中，稍后会把纹理赋值给这个uniform。

```glsl
#version 330 core
out vec4 FragColor;

in vec3 ourColor;
in vec2 TexCoord;

uniform sampler2D ourTexture;

void main()
{
    FragColor = texture(ourTexture, TexCoord);
}
```
使用内建的texture函数来采样纹理的颜色：

- 第一个参数是纹理采样器
- 第二个参数是对应的纹理坐标

这个片段着色器的输出就是纹理的（插值）纹理坐标上的(过滤后的)颜色。

现在只剩下在调用glDrawElements之前绑定纹理了，它会自动把纹理赋值给片段着色器的采样器
```cpp
glBindTexture(GL_TEXTURE_2D, texture);
glBindVertexArray(VAO);
glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
```

### 纹理单元
使用glUniform1i，可以给纹理采样器分配一个位置值，这样的话能够在一个片段着色器中设置多个纹理。一个纹理的位置值通常称为一个纹理单元(Texture Unit)。一个纹理的默认纹理单元是0，它是默认的激活纹理单元，所以上述没有分配一个位置值。

纹理单元的主要目的是在着色器中可以使用多于一个的纹理。通过把纹理单元赋值给采样器，可以一次绑定多个纹理，只要首先激活对应的纹理单元。
可以使用glActiveTexture激活纹理单元，传入需要使用的纹理单元：

```cpp
glActiveTexture(GL_TEXTURE0); // 在绑定纹理之前先激活纹理单元
glBindTexture(GL_TEXTURE_2D, texture);
```

激活纹理单元之后，接下来的glBindTexture函数调用会绑定这个纹理到当前激活的纹理单元，纹理单元GL_TEXTURE0默认总是被激活，所以在前面的例子里当使用glBindTexture的时候，无需激活任何纹理单元。

> OpenGL至少保证有16个纹理单元供你使用，也就是说你可以激活从GL_TEXTURE0到GL_TEXTRUE15。它们都是按顺序定义的，所以也可以通过GL_TEXTURE0 + 8的方式获得GL_TEXTURE8，这在当需要循环一些纹理单元的时候会很有用。

现在需要修改下片段着色器来接收另一个采样器：
```glsl
#version 330 core
...

uniform sampler2D texture1;
uniform sampler2D texture2;

void main()
{
    FragColor = mix(texture(texture1, TexCoord), texture(texture2, TexCoord), 0.2);
}
```
最终输出颜色现在是两个纹理的结合。

mix函数接收三个参数：
- 第一、第二个参数会根据第三个参数进行线性插值
- 第三个参数值为0.0，则返回第一个输入值
- 第三个参数值为1.0，则返回第二个输入值


为了使用第二个纹理（以及第一个），必须改变一点渲染流程，先绑定两个纹理到对应的纹理单元，然后定义哪个uniform采样器对应哪个纹理单元：
```cpp
// 第一个纹理
glActiveTexture(GL_TEXTURE0);
glBindTexture(GL_TEXTURE_2D, texture1);
// 第二个纹理
glActiveTexture(GL_TEXTURE1);
glBindTexture(GL_TEXTURE_2D, texture2);

glBindVertexArray(VAO);
glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
```
还要通过使用glUniform1i设置每个采样器的方式告诉OpenGL每个着色器采样器属于哪个纹理单元。只需要设置一次即可，所以这个会放在渲染循环的前面：
```cpp
ourShader.use(); // 不要忘记在设置uniform变量之前激活着色器程序！
glUniform1i(glGetUniformLocation(ourShader.ID, "texture1"), 0); // 手动设置
ourShader.setInt("texture2", 1); // 或者使用着色器类设置

while(...) 
{
    [...]
}
```

stb_image.h能够在图像加载时帮助翻转y轴，只需要在加载任何图像前加入以下语句即可
```cpp
stbi_set_flip_vertically_on_load(true);
```

### 完整代码：
[github.com/realjf/opengl/src/getting-started/recipe-05](https://github.com/realjf/opengl/tree/master/src/getting-started/recipe-05)

