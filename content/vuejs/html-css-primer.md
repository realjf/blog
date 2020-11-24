---
title: "vue.js 2 系列之三 Html 和 Css 入门"
date: 2020-11-06T14:41:48+08:00
keywords: ["vuejs", "vue.js"]
categories: ["vuejs"]
tags: ["vuejs", "vue.js"]
series: ["pro vue.js2"]
draft: false
toc: false
related:
  threshold: 80
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

## 准备
首先创建项目
```shell script
vue create htmlcss --default
```
安装jquery，bootstrap，popper.js
```shell script
cd htmlcss
npm install jquery
npm install bootstrap@4.0.0
npm install popper
```
在 main.js文件中引入jquery和bootstrap
```js
import Vue from 'vue'
import App from './App.vue'

// 引入jquery
import $ from 'jquery'

Vue.config.productionTip = false

// 添加bootstrap框架
import "bootstrap/dist/css/bootstrap.min.css"

new Vue({
  render: h => h(App),
}).$mount('#app')

```
eslint配置
```shell script
# 进入node_modules目录的.bin目录下，初始化eslint
cd node_modules/.bin/
eslint --init
# 设置选项，除选择vue.js外，其他都选择默认选项

# 最后，将node_modules目录.bin目录下的.eslintrc.js文件拷贝到项目根目录下
# window下
copy .eslintrc.js ..\..\

# linux下
cp .eslintrc.js ../../


```
配置.eslintrc.js的rules
```js
"rules": {
	"generator-star-spacing": "off",
	"no-tabs":"off",
	"no-unused-vars":"off",
	"no-console":"off",
	"no-irregular-whitespace":"off",
	"no-debugger": "off"
},
```

替换App.vue文件中的内容
```html
<template>
<div id="app">
    <h4 class="bg-primary text-white text-center p-2">
        realjf's To Do List
    </h4>
    <div class="container-fluid p-4">
        <div class="row">
            <div class="col font-weight-bold">Task</div>
            <div class="col-2 font-weight-bold">Done</div>
        </div>
        <div class="row" v-for="t in tasks" v-bind:key="t.action">
            <div class="col">{{t.action}}</div>
            <div class="col-2">{{t.done}}</div>
        </div>
    </div>
</div>
</template>

<script>
export default {
    name: "app",
    data() {
        return {
            tasks: [{
                    action: "Buy Flowers",
                    done: false
                },
                {
                    action: "Get Shoes",
                    done: false
                },
                {
                    action: "Collect Tickets",
                    done: true
                },
                {
                    action: "Call Joe",
                    done: false
                }
            ]
        }
    },
};
</script>

```
在项目根目录下运行
```shell script
npm run serve
```

## 理解html元素
html元素的核心就是告诉浏览器如何显示文档内容

html元素包含 开始标签、属性、文档内容、结束标签

### 理解元素内容
元素内容是 开始标签与结束标签包含的内容

### 理解元素属性
元素属性由属性名称和值组成

## 理解bootstrap
- 基础classes，包括bg-primary，text-white等
- 文本classes，包括primary, secondary, success, info等
- margin和padding， 包括 p-2，m-2（其首字母），p-t-1（t表示top）, p-l-1(l表示left)等

### 使用bootstrap创建网格
网格是布局的一种

- container-fluid 
- row（行），通过使用row可以为元素指定一列(column)
- 每行(row)有12列（columns），可以通过使用col- 后接数字特指这个元素占几列（columns），例如col-1表示占一列，col-2占两列，以此类推

### bootstrap的table样式
- table 为table申请通用样式和它的行数
- table-striped 对table的行交替显示不同样式
- table-bordered 为多有的行列显示边界
- table-sm 回收表格中多余空间

```html
<template>
<div id="app">
    <h4 class="bg-primary text-white text-center p-2">
        realjf's To Do List
    </h4>
    <table class="table table-striped table-bordered table-sm">
        <thead>
            <tr>
                <th>Task</th>
                <th>Done</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="t in tasks" v-bind:key="t.action">
                <td>{{t.action}}</td>
                <td>{{t.done}}</td>
            </tr>
        </tbody>
    </table>
</div>
</template>

<script>
export default {
    name: "app",
    data() {
        return {
            tasks: [{
                    action: "Buy Flowers",
                    done: false
                },
                {
                    action: "Get Shoes",
                    done: false
                },
                {
                    action: "Collect Tickets",
                    done: true
                },
                {
                    action: "Call Joe",
                    done: false
                }
            ]
        }
    },
};
</script>

```

### 使用bootstrap对form进行装饰
```html
<template>
<div id="app">
    <h4 class="bg-primary text-white text-center p-2">
        realjf's To Do List
    </h4>
    <table class="table table-striped table-bordered table-sm">
        <thead>
            <tr>
                <th>Task</th>
                <th>Done</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="t in tasks" v-bind:key="t.action">
                <td>{{t.action}}</td>
                <td>{{t.done}}</td>
            </tr>
        </tbody>
    </table>

    <div class="form-group m-2">
        <label>New Item:</label>
        <input v-model="newItemText" class="form-control" />
    </div>
    <div class="text-center">
        <button class="btn btn-primary" v-on:click="addNewTodo">Add</button>
    </div>
</div>
</template>

<script>
export default {
    name: "app",
    data() {
        return {
            tasks: [{
                    action: "Buy Flowers",
                    done: false
                },
                {
                    action: "Get Shoes",
                    done: false
                },
                {
                    action: "Collect Tickets",
                    done: true
                },
                {
                    action: "Call Joe",
                    done: false
                }
            ],
            newItemText: ""
        }
    },
    methods: {
        addNewTodo() {
            this.tasks.push({
                action: this.newItemText,
                done: false
            });
            this.newItemText = "";
        }
    },
};
</script>

```








