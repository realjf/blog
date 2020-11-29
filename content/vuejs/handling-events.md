---
title: "vue.js 2 系列之十四 处理事件 Handling Events"
date: 2020-11-29T14:29:47+08:00
keywords: ["vuejs", "vue.js"]
categories: ["vuejs"]
tags: ["vuejs", "vue.js"]
series: ["pro vue.js2"]
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

本节将学习:

- 使用v-on指令
- 使用事件对象
- 用一个方法处理事件以及接收事件对象作为参数值
- 对您想要的每个事件应用v-on指令，使用事件对象接收或检测事件类型
- 使用事件传播修饰符
- 使用鼠标和键盘修饰符


## 处理事件
v-on指令被用于处理事件,其格式如下：
```html
<h3 v-on:click="name='Clicked!'"></h3>
```
其中： 

- v-on是指令
- click是事件参数
- name='Clicked!' 是表达式

## 理解事件和事件对象
有许多可用的事件类型，如下：

| 事件类型| 描述 |
|:---:|:---:|
|click| 当鼠标在一个元素边界内部被按下并释放时触发 |
| mousedown| 鼠标按钮在元素边界内被按下时触发|
|mousemove| 鼠标在元素边界内移动时触发 |
|mouseleave| 鼠标离开元素边界时触发 |
|keydown| 一个按键按下时触发|

有用的事件对象自有属性
| 自有属性| 描述|
|:---:|:---:|
| target | 该属性返回当前事件触发的html元素的DOM对象 |
| currentTarget | 该属性返回当前正在被处理事件的HTML元素的DOM对象，不同于target |
| type | 该属性返回事件类型 |
| key | 对于键盘事件，该属性返回事件关联的key |

v-on指令可以通过$event变量访问事件对象。
```html
<h3 v-on:click="name=$event.type">{{name}}</h3>
```

## 使用一个方法处理事件

```html
<h3 v-on:click="handleEvent">{{name}}</h3>

...
methods:{
    handleEvent($event){
        this.name = $event.type;
}
}
...
```

当然也可以传参数给处理函数
```html
<h3 v-on:click="handleEvent('SoccerBall', $event)">{{name}}</h3>

...
methods:{
    handleEvent(name, $event){
        this.name = `${name} - ${$event.type}`;
    }
}
```

#### 使用指令简略表达式

v-on指令可以简写成@，如v-on:click可以简写成@click。

## 合并事件，方法和重复元素
可以自己利用v-for指令、v-on指令以及methods里定义的事件处理函数练习以下，这里就不提供示例代码了

## 为同一个元素监听多个事件

有两种方法可以为同一个元素监听处理不同的事件：

- 第一：应用v-on指令分别为每一个事件提供处理函数

```html
<button v-on:click="handleClick(name)"
    v-on:mousemove="handleMouseEvent(name, $event)"
    v-on:mouseleave="handleMouseEvent(name, $event)"
></button>
```
> 两个handleMouseEvent函数通过$event.type进行区分

- 第二：应用没有事件参数的v-on指令，并设置指令的表达式为一个事件类型为键和可调用方法为其值的对象

```html
<button v-on="buttonEvents" v-bind:data-name="name"></button>

...
data: function() {
    buttonEvents: {
        click: this.handleClick,
        mousemove: this.handleMouseEvent,
        mouseleave: this.handleMouseEvent,
    }
},
methods: {
    handleClick($event){
        let name = $event.target.dataset.name;
        this.message = `Select: ${name}`;
    },
    handleMouseEvent($event){
        let name = $event.target.dataset.name;
        if($event.type == "mousemove"){
            this.message = `Move in ${name} ${this.counter++}`;
        }else{
            this.counter = 0;
            this.message = "Ready";
        }
    }
}
...
```

其中dataset自有属性可以访问html中自定义属性data-attributes以获取其值


## 使用事件处理修饰符

为了保持事件处理方法简单和可聚焦，v-on指令提供里修饰符集代表了其要求的js状态，如下

| 修饰符| 描述|
|:---:|:---:|
| stop | 此修饰符相当于调用事件对象上的stoppagation方法，“停止事件传播”|
| prevent| 此修饰符相当于对事件对象调用preventDefault方法 |
| capture | 此修饰符启用事件传播的捕获模式|
| self| 只有当事件源于已应用指令的元素|
| once | 此修饰符将阻止同一类型的后续事件调用处理程序方法|
| passive | 此修饰符将启用被动事件侦听，从而提高性能在移动设备上特别有用 |

### 管理事件传播

#### 在capture修饰符下接收事件
```html
<div id="outer-element" v-on:click.capture="handleClick"></div>
```
v-on指令在捕获事件期间不接收其他事件，除非capture修饰符已经被应用过了。

#### 只处理目标的修饰符事件
```html
<div id="middle-element" v-on:click.self="handleClick"></div>
```
只处理当前id为middle-element的元素的事件

#### 停止事件传播
stop修饰符停止事件的传播，防止其被元素的v-on指令任何后续事件处理
```html
<div id="middle-element" class="bg-secondary p-4" v-on:click.stop="handleClick"></div>
```


### 防止重复事件
once修饰符阻止v-on指令多次调用其方法。这并不能阻止正常的事件传播过程，
但它确实阻止元素在第一个事件已经处理之后再参与其中。
```html
<div id="inner-element" class="bg-info p-4" v-on:click.once="handleClick"></div>
```


## 使用鼠标事件修饰符
v-on指令提供里一个鼠标事件处理的修饰符集

| 修饰符| 描述 |
|:---:|:---:|
| left | 该修饰符只选择在鼠标左键时触发 |
| middle | 该修饰符只选择在鼠标中键时触发 |
| right | 该修饰符只选择在鼠标右键时触发 |



## 使用键盘事件修饰符
v-on指令提供里一个键盘事件处理的修饰符集

| 修饰符| 描述 |
|:---:|:---:|
| left | 该修饰符选择在左方向键时触发 |
| enter | 该修饰符选择在enter键时触发 |
| right | 该修饰符选择在右方向键时触发 |
| up | 该修饰符选择在上方向键时触发 |
| down | 该修饰符选择在下方向键时触发 |
| tab | 该修饰符选择在tab键时触发 |
| delete | 该修饰符选择在delete键时触发 |
| esc | 该修饰符选择在esc键时触发 |
| space | 该修饰符选择在空格键时触发 |
| ctrl | 该修饰符选择在control键时触发 |
| alt | 该修饰符选择在alt键时触发 |
| shift | 该修饰符选择在shift键时触发 |
| meta | 该修饰符选择在meta键时触发 |
| exact | 该修饰符选择只在特定某个修饰键时触发，而不是组合键 |

