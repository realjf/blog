---
title: "opengl之八 摄像机 Camera"
date: 2021-05-10T17:01:49+08:00
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

## 摄像机
OpenGL本身没有摄像机(Camera)的概念，但可以通过把场景中的所有物体往相反方向移动的方式来模拟出摄像机，产生一种在移动的感觉，而不是场景在移动。

### 摄像机/观察空间
观察矩阵把所有的世界坐标变换为相对于摄像机位置与方向的观察坐标。要定义一个摄像机，需要它在世界空间中的位置、观察的方向、一个指向它右侧的向量以及一个指向它上方的向量。

![摄像机](/image/camera_axes.png)
#### 1. 摄像机的位置
摄像机位置简单来说就是世界空间中一个指向摄像机位置的向量
```cpp
glm::vec3 cameraPos = glm::vec3(0.0f, 0.0f, 3.0f);
```
> 不要忘记正z轴是从屏幕指向你的，如果希望摄像机向后移动，就沿着z轴的正方向移动。

#### 2. 摄像机方向
用场景原点向量减去摄像机位置向量的结果就是摄像机的指向向量。

```cpp
glm::vec3 cameraTarget = glm::vec3(0.0f, 0.0f, 0.0f);
glm::vec3 cameraDirection = glm::normalize(cameraPos - cameraTarget);
```

#### 3. 右轴
需要的另一个向量是一个右向量(Right Vector)，它代表摄像机空间的x轴的正方向。为获取右向量需要先使用一个小技巧：先定义一个上向量(Up Vector)。接下来把上向量和第二步得到的方向向量进行叉乘。两个向量叉乘的结果会同时垂直于两向量，因此会得到指向x轴正方向的那个向量

```cpp
glm::vec3 up = glm::vec3(0.0f, 1.0f, 0.0f); 
glm::vec3 cameraRight = glm::normalize(glm::cross(up, cameraDirection));
```

#### 4. 上轴
把右向量和方向向量进行叉乘：
```cpp
glm::vec3 cameraUp = glm::cross(cameraDirection, cameraRight);
```
使用这些摄像机向量就可以创建一个LookAt矩阵了

### Look At
如果你使用3个相互垂直（或非线性）的轴定义了一个坐标空间，你可以用这3个轴外加一个平移向量来创建一个矩阵，并且你可以用这个矩阵乘以任何向量来将其变换到那个坐标空间。这正是LookAt矩阵所做的，现在有了3个相互垂直的轴和一个定义摄像机空间的位置坐标，就可以创建LookAt矩阵了：

![look at](/image/look_at.png)

其中R是右向量，U是上向量，D是方向向量P是摄像机位置向量。注意，位置向量是相反的，因为我们最终希望把世界平移到与我们自身移动的相反方向。

把这个LookAt矩阵作为观察矩阵可以很高效地把所有世界坐标变换到刚刚定义的观察空间。

GLM已经提供了这些支持。要做的只是定义一个摄像机位置，一个目标位置和一个表示世界空间中的上向量的向量
```cpp
glm::mat4 view;
view = glm::lookAt(glm::vec3(0.0f, 0.0f, 3.0f), 
           glm::vec3(0.0f, 0.0f, 0.0f), 
           glm::vec3(0.0f, 1.0f, 0.0f));
```

来做些有意思的事，把摄像机在场景中旋转。

预先定义这个圆的半径radius，在每次渲染迭代中使用GLFW的glfwGetTime函数重新创建观察矩阵，来扩大这个圆。
```cpp
float radius = 10.0f;
float camX = sin(glfwGetTime()) * radius;
float camZ = cos(glfwGetTime()) * radius;
glm::mat4 view;
view = glm::lookAt(glm::vec3(camX, 0.0, camZ), glm::vec3(0.0, 0.0, 0.0), glm::vec3(0.0, 1.0, 0.0)); 
```
完整代码如下：[github.com/realjf/opengl/src/recipe-09](https://github.com/realjf/opengl/tree/master/src/recipe-09)

## 自由移动
首先设置一个摄像机系统，
```cpp
glm::vec3 cameraPos   = glm::vec3(0.0f, 0.0f,  3.0f);
glm::vec3 cameraFront = glm::vec3(0.0f, 0.0f, -1.0f);
glm::vec3 cameraUp    = glm::vec3(0.0f, 1.0f,  0.0f);
```
LookAt函数现在成了
```cpp
view = glm::lookAt(cameraPos, cameraPos + cameraFront, cameraUp);
```
首先将摄像机位置设置为之前定义的cameraPos。方向是当前的位置加上刚刚定义的方向向量。这样能保证无论怎么移动，摄像机都会注视着目标方向。

processInput函数添加几个需要检查的按键命令
```cpp
void processInput(GLFWwindow *window)
{
    ...
    float cameraSpeed = 0.05f; // adjust accordingly
    if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS)
        cameraPos += cameraSpeed * cameraFront;
    if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS)
        cameraPos -= cameraSpeed * cameraFront;
    if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS)
        cameraPos -= glm::normalize(glm::cross(cameraFront, cameraUp)) * cameraSpeed;
    if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS)
        cameraPos += glm::normalize(glm::cross(cameraFront, cameraUp)) * cameraSpeed;
}
```
现在应该可以移动摄像机了

## 移动速度
当你发布你的程序的时候，你必须确保它在所有硬件上移动速度都一样。

图形程序和游戏通常会跟踪一个时间差(Deltatime)变量，它储存了渲染上一帧所用的时间。把所有速度都去乘以deltaTime值。结果就是，如果deltaTime很大，就意味着上一帧的渲染花费了更多时间，所以这一帧的速度需要变得更高来平衡渲染所花去的时间。使用这种方法时，无论你的电脑快还是慢，摄像机的速度都会相应平衡，这样每个用户的体验就都一样了。

跟踪两个全局变量来计算出deltaTime值：
```cpp
float deltaTime = 0.0f; // 当前帧与上一帧的时间差
float lastFrame = 0.0f; // 上一帧的时间
```
在每一帧中计算出新的deltaTime以备后用。
```cpp
float currentFrame = glfwGetTime();
deltaTime = currentFrame - lastFrame;
lastFrame = currentFrame;
```

现在，在计算速度的时候可以将其考虑进去了
```cpp
void processInput(GLFWwindow *window)
{
  float cameraSpeed = 2.5f * deltaTime;
  ...
}
```
完整代码如下：[github.com/realjf/opengl/src/recipe-10](https://github.com/realjf/opengl/tree/master/src/recipe-10)


## 视角移动






