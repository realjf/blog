---
title: "opengl光照之三 材质 Materials"
date: 2021-05-13T10:14:28+08:00
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

每个物体对镜面高光也有不同的反应。有些物体反射光的时候不会有太多的散射(Scatter)，因而产生一个较小的高光点，而有些物体则会散射很多，产生一个有着更大半径的高光点。如果想要在OpenGL中模拟多种类型的物体，必须为每个物体分别定义一个材质(Material)属性。


当描述一个物体的时候，可以用这三个分量来定义一个材质颜色(Material Color)：环境光照(Ambient Lighting)、漫反射光照(Diffuse Lighting)和镜面光照(Specular Lighting)。再添加反光度(Shininess)这个分量到上述的三个颜色中，这就有所有材质属性了：
```glsl
#version 330 core
struct Material {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    float shininess;
}; 

uniform Material material;
```
在片段着色器中，创建一个结构体(Struct)来储存物体的材质属性。也可以把它们储存为独立的uniform值，但是作为一个结构体来储存会更有条理一些。首先定义结构体的布局(Layout)，然后使用刚创建的结构体为类型，简单地声明一个uniform变量。

- ambient材质向量定义了在环境光照下这个物体反射得是什么颜色，通常这是和物体颜色相同的颜色。
- diffuse材质向量定义了在漫反射光照下物体的颜色。（和环境光照一样）漫反射颜色也要设置为需要的物体颜色。
- specular材质向量设置的是镜面光照对物体的颜色影响（或者甚至可能反射一个物体特定的镜面高光颜色）。
- 最后，shininess影响镜面高光的散射/半径。

这四个元素定义了一个物体的材质，通过它们能够模拟很多现实世界中的材质。

[devernay.free.fr](http://devernay.free.fr/cours/opengl/materials.html)上的一个表格展示了几种材质属性，它们模拟了现实世界中的真实材质。


让我们在着色器中实现这样的一个材质系统。
### 设置材质
在片段着色器中创建了一个材质结构体的uniform，由于所有材质变量都储存在结构体中，可以从uniform变量material中访问它们：

```glsl
void main()
{    
    // 环境光
    vec3 ambient = lightColor * material.ambient;

    // 漫反射 
    vec3 norm = normalize(Normal);
    vec3 lightDir = normalize(lightPos - FragPos);
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = lightColor * (diff * material.diffuse);

    // 镜面光
    vec3 viewDir = normalize(viewPos - FragPos);
    vec3 reflectDir = reflect(-lightDir, norm);  
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
    vec3 specular = lightColor * (spec * material.specular);  

    vec3 result = ambient + diffuse + specular;
    FragColor = vec4(result, 1.0);
}
```
这次是根据材质的颜色来计算最终的输出颜色的。物体的每个材质属性都乘上了它们对应的光照分量。

现在可以在程序中设置适当的uniform，对物体设置材质了。GLSL中的结构体在设置uniform时并没有什么特别之处。结构体只是作为uniform变量的一个封装，所以如果想填充这个结构体的话，仍需要对每个单独的uniform进行设置，但这次要带上结构体名的前缀：
```cpp
materialsShader.setVec3("material.ambient",  1.0f, 0.5f, 0.31f);
materialsShader.setVec3("material.diffuse",  1.0f, 0.5f, 0.31f);
materialsShader.setVec3("material.specular", 0.5f, 0.5f, 0.5f);
materialsShader.setFloat("material.shininess", 32.0f);
```
将环境光和漫反射分量设置成想要让物体所拥有的颜色，而将镜面分量设置为一个中等亮度的颜色，不希望镜面分量在这个物体上过于强烈。将反光度保持为32。现在能够程序中非常容易地修改物体的材质了。

#### 光的属性
这个物体太亮了。物体过亮的原因是环境光、漫反射和镜面光这三个颜色对任何一个光源都会去全力反射。光源对环境光、漫反射和镜面光分量也具有着不同的强度。

通过使用一个强度值改变环境光和镜面光强度的方式解决了这个问题。如果想做一个类似的系统，但是这次是要为每个光照分量都指定一个强度向量。如果假设lightColor是vec3(1.0)，代码会看起来像这样：

```glsl
vec3 ambient  = vec3(1.0) * material.ambient;
vec3 diffuse  = vec3(1.0) * (diff * material.diffuse);
vec3 specular = vec3(1.0) * (spec * material.specular);
```
所以物体的每个材质属性对每一个光照分量都返回了最大的强度。对单个光源来说，这些vec3(1.0)值同样可以分别改变，现在，物体的环境光分量完全地影响了立方体的颜色，可是环境光分量实际上不应该对最终的颜色有这么大的影响，所以将光源的环境光强度设置为一个小一点的值，从而限制环境光颜色

```glsl
vec3 ambient = vec3(0.1) * material.ambient;
```
为光照属性创建一个与材质结构体类似的结构体：
```glsl
struct Light {
    vec3 position;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

uniform Light light;
```
一个光源对它的ambient、diffuse和specular光照有着不同的强度。环境光照通常会设置为一个比较低的强度。光源的漫反射分量通常设置为光所具有的颜色，通常是一个比较明亮的白色。镜面光分量通常会保持为vec3(1.0)，以最大强度发光。

和材质uniform一样，需要更新片段着色器：
```glsl
vec3 ambient  = light.ambient * material.ambient;
vec3 diffuse  = light.diffuse * (diff * material.diffuse);
vec3 specular = light.specular * (spec * material.specular);
```
在程序中设置光照强度：
```cpp
materialsShader.setVec3("light.ambient",  0.2f, 0.2f, 0.2f);
materialsShader.setVec3("light.diffuse",  0.5f, 0.5f, 0.5f); // 将光照调暗了一些以搭配场景
materialsShader.setVec3("light.specular", 1.0f, 1.0f, 1.0f); 
```

#### 不同的光源颜色
不同的光照颜色能够极大地影响物体的最终颜色输出。由于光照颜色能够直接影响物体能够反射的颜色

可以利用sin和glfwGetTime函数改变光源的环境光和漫反射颜色，从而很容易地让光源的颜色随着时间变化：
```glsl
glm::vec3 lightColor;
lightColor.x = sin(glfwGetTime() * 2.0f);
lightColor.y = sin(glfwGetTime() * 0.7f);
lightColor.z = sin(glfwGetTime() * 1.3f);

glm::vec3 diffuseColor = lightColor   * glm::vec3(0.5f); // 降低影响
glm::vec3 ambientColor = diffuseColor * glm::vec3(0.2f); // 很低的影响

lightingShader.setVec3("light.ambient", ambientColor);
lightingShader.setVec3("light.diffuse", diffuseColor);
```
### 完整源码
[github.com/realjf/opengl/src/lighting/03](https://github.com/realjf/opengl/tree/master/src/lighting/03)


