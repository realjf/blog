---
title: "vue.js 2 系列之九 理解vue.js Understanding Vuejs 2"
date: 2020-11-14T20:31:27+08:00
keywords: ["vuejs", "vue.js"]
categories: ["vuejs"]
tags: ["vuejs", "vue.js"]
series: ["pro vue.js2"]
draft: false
toc: false
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

## 准备
创建项目
```shell script
vue create nomagic
```

在项目根目录下添加新文件vue.config.js
```javascript
module.exports = {
    runtimeCompiler: true
}
```

在项目根目录下运行
```shell script
npm install bootstrap@4.0.0
```

在main.js里添加bootstrap.min.css如下内容
```javascript

import Vue from 'vue'
import App from './App.vue'

import "bootstrap/dist/css/bootstrap.min.css";

Vue.config.productionTip = false

new Vue({
  render: h => h(App),
}).$mount('#app')

```
运行例子
```shell script
npm run serve
```
## 使用DOM API创建应用

在main.js中添加如下内容：
```javascript
require('../node_modules/bootstrap/dist/css/bootstrap.min.css')

let counter = 1;

let container = document.createElement("div");
container.classList.add("text-center", "p-3");

let msg = document.createElement("h1");
msg.classList.add("bg-primary", "text-white", "p-3");
msg.textContent = "Button Not Pressed";

let button = document.createElement("button");
button.textContent = "Press Me";
button.classList.add("btn", "btn-secondary");
button.onclick = () => msg.textContent = `Button Presses: ${counter++}`;

container.appendChild(msg);
container.appendChild(button);

let app = document.getElementById("app");
app.parentElement.replaceChild(container, app);


```
这个html文档已经存在的id是app,用div元素替换里它

## 创建一个vue对象
在main.js文件中添加如下内容：
```javascript
require('../node_modules/bootstrap/dist/css/bootstrap.min.css')

import Vue from "vue"

new Vue({
  el: "#app",
  template: `<div class="text-center p-3">
    <h1 class="bg-secondary text-white p-3">Vue: Button Not Pressed</h1>
    <button class="btn btn-secondary">Press Me</button>
  </div>`
})

```
在vue对象中添加数据，添加变量在main.js中
```javascript
require('../node_modules/bootstrap/dist/css/bootstrap.min.css')

import Vue from "vue"

new Vue({
  el: "#app",
  template: `<div class="text-center p-3">
    <h1 class="bg-secondary text-white p-3">Button Presses: {{counter}}</h1>
    <button class="btn btn-secondary">Press Me</button>
  </div>`,
  data: {
    counter: 0
  }
})


```
添加事件
```javascript
require('../node_modules/bootstrap/dist/css/bootstrap.min.css')

import Vue from "vue"

new Vue({
  el: "#app",
  template: `<div class="text-center p-3">
    <h1 class="bg-secondary text-white p-3">Button Presses: {{counter}}</h1>
    <button class="btn btn-secondary" v-on:click="handleClick">Press Me</button>
  </div>`,
  data: {
    counter: 0
  },
  methods: {
    handleClick(){
      this.counter++;
    }
  }
})
```
显示信息
```javascript
require('../node_modules/bootstrap/dist/css/bootstrap.min.css')

import Vue from "vue"

new Vue({
  el: "#app",
  template: `<div class="text-center p-3">
    <h1 class="bg-secondary text-white p-3">{{message}}</h1>
    <button class="btn btn-secondary" v-on:click="handleClick">Press Me</button>
  </div>`,
  data: {
    counter: 0
  },
  methods: {
    handleClick(){
      this.counter++;
    }
  },
  computed: {
    message() {
      return this.counter == 0 ? "Button Not Pressed" : `Button Presses: ${this.counter}`;
    }
  }
})

```
理解vue对象结构

![vue对象结构](/image/vue-object-structure.png)

## 介绍一个组件
改写App.vue内容
```html

<script>
export default {
    template: `<div class="text-center p-3">
    <h1 class="bg-secondary text-white p-3">
      {{message}}
    </h1>
    <button class="btn btn-secondary" v-on:click="handleClick">Press Me</button>
  </div>`,
    data: function () {
        return {
            counter: 0,
        }
    },
    methods: {
        handleClick() {
            this.counter++;
        }
    },
    computed: {
        message() {
            return this.counter == 0 ? "Button Not Pressed" : `Button Presses: ${this.counter}`;
        }
    },
}
</script>

```
注册申请组件，main.js文件内容如下：
```javascript
require('../node_modules/bootstrap/dist/css/bootstrap.min.css')

import Vue from "vue"
import MyComponent from "./App";

new Vue({
  el: "#app",
  components: {"custom": MyComponent},
  template: `<div class="text-center">
    <h1 class="bg-primary text-white p-3">This is the main.js file</h1>
    <custom/>
  </div>`
})

```

然后移除模板内容main.js文件
```javascript
require('../node_modules/bootstrap/dist/css/bootstrap.min.css')

import Vue from "vue"
import MyComponent from "./App";

new Vue({
  el: "#app",
  components: {"custom": MyComponent},
  template: "<custom/>"
})

```
### 从js代码中分离出模板

在App.vue文件中使用模板元素
```html
<template>
<div class="text-center p-3">
    <h1 class="bg-secondary text-white p-3">
        {{message}}
    </h1>
    <button class="btn btn-secondary" v-on:click="handleClick">Press Me</button>
</div>
</template>

<script>
export default {
    data: function () {
        return {
            counter: 0,
        }
    },
    methods: {
        handleClick() {
            this.counter++;
        }
    },
    computed: {
        message() {
            return this.counter == 0 ? "Button Not Pressed" : `Button Presses: ${this.counter}`;
        }
    },
}
</script>

```
### 使用分离javascript和html文件
App.html中的内容如下：
```html
<div class="text-center p-3">
    <h1 class="bg-secondary text-white p-3">
        {{message}}
    </h1>
    <button class="btn btn-secondary" v-on:click="handleClick">Press Me</button>
</div>
```
App.vue文件内容如下：

```html

<template src="./App.html"></template>

<script>
export default {
    data: function () {
        return {
            counter: 0,
        }
    },
    methods: {
        handleClick() {
            this.counter++;
        }
    },
    computed: {
        message() {
            return this.counter == 0 ? "Button Not Pressed" : `Button Presses: ${this.counter}`;
        }
    },
}
</script>

```






