---
title: "vue.js 2 系列之四 javascript入门 Js Primer"
date: 2020-11-06T15:35:03+08:00
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
vue create jsprimer --default
```
安装jquery，bootstrap，popper.js
```shell script
cd jsprimer
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
配置package.json的eslintConfig里的rules
```javascript
"rules": {
    "no-unused-vars":"off",
	"no-console":"off",
	"no-declare": "off"
},
```
运行项目
```shell script
npm run serve
```

## 函数
### 定义函数，包括缺省值，函数返回值，
在main.js中添加如下代码
```js
func myFunc(name, age = 18) {
    return "Hello " + name + ", your age is " + age.toString() + ", right?";
}

console.log(myFunc("realjf"));

```

### 使用=>定义函数
```javascript
const myFunc = (name, age = 18) => ("Hello " + name + ", your age is " + age.toString() + ", right?");
```

## 使用定义变量
- let定义局部变量
- var定义全局变量

## 类型转换
数值转字符串
```javascript
let a = (5).toString() + String(5);
console.log(a);
```
字符串转数值
```javascript
let a = "5";
let b = "5";

let c = Number(a) + parseInt(b);
console.log(c);

```

## 数组
```javascript
let myArr = new Array();
myArr[0] = 100;
myArr[1] = "realjf";
myArr[3] = true;
```
还可以使用很多内建的数组函数，如：pop(),shift(),join()，concat()，sort(),forEach()等

## 对象
```javascript
let person = new Object();
person.name = "realjf";
person.age = 18;

console.log(person.name);
console.log(person.age);


let alive = true;
let fish = {
    name: "cc",
    age: 1,
    alive,
    bubble: function(){
    console.log("fish bubble");
}
};

console.log(fish.alive);
console.log(fish.bubble());

// copy properties to anther
let fish1 = {};

Object.assign(fish1, fish);

fish1.bubble();

```
## 理解javascript模块
### 创建和使用简单的javascript模块

在src/maths目录下新建一个文件sum.js，其内容如下：
```javascript
export default function(values){
    return values.reduce((total, val) => total + val, 0);
}
```
这里有两个关键字在定义模块时

- export，用于指定导出模块功能供外部使用，当然也可以导出常量、函数、文件、模块等
- default，当模块包含单一功能时使用
- 在一个文件或者模块中，export可以有多个，但是export default只能有一个
- 使用import关键字进行导入
- 使用export default导出，在导入时需要加{}，export default则不需要
- export default表示为模块指定默认输出，这样就不需要知道索要加载的模块的变量名

### 使用模块
```javascript
import additionFunction from "./maths/sum";
let values = [10, 20, 30, 40, 50];
let total = additionFunction(values);

```
### 定义多功能模块
在src/maths/operations.js中添加如下代码
```javascript
export function multiply(values) {
    return values.reduce((total, val) => total * val, 1);
}

export function subtract(amount, values) {
    return values.reduce((total, val) => total - val, amount);
}

export function divide(first, second) {
    return first/second;
}

```

使用模块
```javascript
import { multiply, subtract } from "./maths/operations";

let values = [10 ,20, 30, 40, 50];
console.log(`multiply: ${multiply(values)}`);
```
修改模块名称
```javascript
import { multiply, subtract as minus } from "./maths/operations";
```
导入整个模块
```javascript
import * as ops from "./maths/operations";
```

### 组合多个文件的模块
在src/maths/ops.js中添加如下代码
```javascript
import addition from "./sum";

export function mean(values) {
    return addition(values)/values.length;
}

export { addition };
export * from "./operations";
```
### 从一个多文件模块中导入单独功能
```javascript
import { addition as add, multiply, subtract, mean as average } from "./maths";
```

## 理解promises
### 异步操作问题
web应用经典的异步操作是一个http请求，典型的用于获取用户请求的数据和内容

```javascript
export function asyncAdd(values) {
    setTimeout(() => {
    let total = addition(values);
    console.log(`Async Total: ${total}`);
    return total;
}, 500);
}
```
### 使用promise
```javascript
export function asyncAdd(values) {
    return new Promise((callback) => {
    setTimeout(() => {
let total = addition(values);
    console.log(`Async Total: ${total}`);
    callback(total);
}, 500);
    
});
}
```
上述代码使用promise异步获取setTimeout返回的值

#### 异步操作关键字： async和await
```javascript
import { asyncAdd } from "./maths";

let values = [10, 20, 30, 40, 50];

async function doTask() {
    let total = await asyncAdd(values);
    console.log(`Main Total: ${total}`);
}

doTask();

```








