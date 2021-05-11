---
title: "opengl之八 摄像机 Camera"
date: 2021-05-10T17:01:49+08:00
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

### 欧拉角

一共有3种欧拉角：俯仰角(Pitch)、偏航角(Yaw)和滚转角(Roll)，下面的图片展示了它们的含义：

![欧拉角](/image/camera_pitch_yaw_roll.png)

俯仰角是描述如何往上或往下看的角，可以在第一张图中看到。第二张图展示了偏航角，偏航角表示往左和往右看的程度。滚转角代表如何翻滚摄像机，通常在太空飞船的摄像机中使用。每个欧拉角都有一个值来表示，把三个角结合起来就能够计算3D空间中任何的旋转向量了。


![计算欧拉角](/image/camera_pitch.png)

可以看到对于一个给定俯仰角的y值等于sin θ：
```cpp
direction.y = sin(glm::radians(pitch)); // 注意先把角度转为弧度
```
从三角形中可以看到x和z的分量值等于：
```cpp
direction.x = cos(glm::radians(pitch));
direction.z = cos(glm::radians(pitch));
```
z值同样取决于偏航角的正弦值。把这个加到前面的值中，会得到基于俯仰角和偏航角的方向向量：
```cpp
direction.x = cos(glm::radians(pitch)) * cos(glm::radians(yaw)); // 译注：direction代表摄像机的前轴(Front)，这个前轴是和本文第一幅图片的第二个摄像机的方向向量是相反的
direction.y = sin(glm::radians(pitch));
direction.z = cos(glm::radians(pitch)) * sin(glm::radians(yaw));
```

### 鼠标输入
首先要告诉GLFW，它应该隐藏光标，并捕捉(Capture)它。捕捉光标表示的是，如果焦点在你的程序上（译注：即表示你正在操作这个程序，Windows中拥有焦点的程序标题栏通常是有颜色的那个，而失去焦点的程序标题栏则是灰色的），光标应该停留在窗口中（除非程序失去焦点或者退出）
```cpp
glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
```
在调用这个函数之后，无论怎么去移动鼠标，光标都不会显示了，它也不会离开窗口。对于FPS摄像机系统来说非常完美。

为了计算俯仰角和偏航角，需要让GLFW监听鼠标移动事件。函数的原型如下：
```cpp
void mouse_callback(GLFWwindow* window, double xpos, double ypos);
```
这里的xpos和ypos代表当前鼠标的位置。当用GLFW注册了回调函数之后，鼠标一移动mouse_callback函数就会被调用：
```cpp
glfwSetCursorPosCallback(window, mouse_callback);
```
在处理FPS风格摄像机的鼠标输入的时候，必须在最终获取方向向量之前做下面这几步：

- 计算鼠标距上一帧的偏移量。
- 把偏移量添加到摄像机的俯仰角和偏航角中。
- 对偏航角和俯仰角进行最大和最小值的限制。
- 计算方向向量。

第一步是计算鼠标自上一帧的偏移量。必须先在程序中储存上一帧的鼠标位置，把它的初始值设置为屏幕的中心（屏幕的尺寸是800x600）：
```cpp
float lastX = 400, lastY = 300;
```
然后在鼠标的回调函数中计算当前帧和上一帧鼠标位置的偏移量：
```cpp
float xoffset = xpos - lastX;
float yoffset = lastY - ypos; // 注意这里是相反的，因为y坐标是从底部往顶部依次增大的
lastX = xpos;
lastY = ypos;

float sensitivity = 0.05f;
xoffset *= sensitivity;
yoffset *= sensitivity;
```
把偏移量乘以了sensitivity（灵敏度）值。如果忽略这个值，鼠标移动就会太大了；你可以自己实验一下，找到适合自己的灵敏度值。

接下来把偏移量加到全局变量pitch和yaw上：
```cpp
yaw   += xoffset;
pitch += yoffset;
```
第三步，需要给摄像机添加一些限制，这样摄像机就不会发生奇怪的移动了（这样也会避免一些奇怪的问题）。对于俯仰角，要让用户不能看向高于89度的地方（在90度时视角会发生逆转，所以把89度作为极限），同样也不允许小于-89度。这样能够保证用户只能看到天空或脚下，但是不能超越这个限制。可以在值超过限制的时候将其改为极限值来实现：
```cpp
if(pitch > 89.0f)
  pitch =  89.0f;
if(pitch < -89.0f)
  pitch = -89.0f;
```

第四也是最后一步，就是通过俯仰角和偏航角来计算以得到真正的方向向量：
```cpp
glm::vec3 front;
front.x = cos(glm::radians(pitch)) * cos(glm::radians(yaw));
front.y = sin(glm::radians(pitch));
front.z = cos(glm::radians(pitch)) * sin(glm::radians(yaw));
cameraFront = glm::normalize(front);
```
计算出来的方向向量就会包含根据鼠标移动计算出来的所有旋转了。由于cameraFront向量已经包含在GLM的lookAt函数中，这就没什么问题了。

如果你现在运行代码，你会发现在窗口第一次获取焦点的时候摄像机会突然跳一下。这个问题产生的原因是，在你的鼠标移动进窗口的那一刻，鼠标回调函数就会被调用，这时候的xpos和ypos会等于鼠标刚刚进入屏幕的那个位置。这通常是一个距离屏幕中心很远的地方，因而产生一个很大的偏移量，所以就会跳了。可以简单的使用一个bool变量检验是否是第一次获取鼠标输入，如果是，那么先把鼠标的初始位置更新为xpos和ypos值，这样就能解决这个问题；接下来的鼠标移动就会使用刚进入的鼠标位置坐标来计算偏移量了：
```cpp
if(firstMouse) // 这个bool变量初始时是设定为true的
{
    lastX = xpos;
    lastY = ypos;
    firstMouse = false;
}
```
最后代码是这样的：
```cpp
void mouse_callback(GLFWwindow* window, double xpos, double ypos)
{
    if(firstMouse)
    {
        lastX = xpos;
        lastY = ypos;
        firstMouse = false;
    }

    float xoffset = xpos - lastX;
    float yoffset = lastY - ypos; 
    lastX = xpos;
    lastY = ypos;

    float sensitivity = 0.05;
    xoffset *= sensitivity;
    yoffset *= sensitivity;

    yaw   += xoffset;
    pitch += yoffset;

    if(pitch > 89.0f)
        pitch = 89.0f;
    if(pitch < -89.0f)
        pitch = -89.0f;

    glm::vec3 front;
    front.x = cos(glm::radians(yaw)) * cos(glm::radians(pitch));
    front.y = sin(glm::radians(pitch));
    front.z = sin(glm::radians(yaw)) * cos(glm::radians(pitch));
    cameraFront = glm::normalize(front);
}
```
完整代码如下：[github.com/realjf/opengl/src/recipe-10](https://github.com/realjf/opengl/tree/master/src/recipe-10)

### 摄像机类
[github.com/realjf/opengl/src/recipe-10/camera.hpp](https://github.com/realjf/opengl/tree/master/src/recipe-10/camera.hpp)


