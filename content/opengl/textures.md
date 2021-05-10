---
title: "opengl之五 纹理 Textures"
date: 2021-05-10T11:30:39+08:00
keywords: ["opengl"]
categories: ["opengl"]
tags: ["opengl"]
series: [""]
draft: true
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




### 加载与创建纹理


