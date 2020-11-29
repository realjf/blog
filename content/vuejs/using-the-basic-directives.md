---
title: "vue.js 2 系列之十二 使用基本指令 Using the Basic Directives"
date: 2020-11-29T12:38:13+08:00
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

## v-on指令，处理事件
```html
<a v-on:click="handleClick"></a>
```
v-on指令用于处理事件。此指令已配置通过click点击事件调用方法称为handleClick。在组件脚本的methods部分定义了这个方法元素。

## v-text指令，设置元素的文本内容

```html
<span v-text="name"></span>
```
这是v-text指令，用于设置元素的文本内容，该指令将完整的替换元素的内容。
如上，span元素的内容将是name变量的内容。


## v-html指令，以html方式解析显示内容
```html
<span v-html="fragment"></span>
```
该指令将fragment变量的内容作为html数据显示。

## v-if指令，可选的显示元素
```html
<h4 v-if="showElements">{{ price }}</h4>
```
该指令判断showElements变量是否为真，如果为真，则h4标签可见，如果为假，则不可见。
这里的不可见表示不是隐藏，而是不生成标签，也不占空间。

## v-else,v-else-if指令，与v-if指令联合使用，功能相似
```html
<h3 v-if="counter % 3 == 0">1</h3>
<h3 v-else-if="counter % 3 == 1">2</h3>
<h3 v-else="counter % 3 == 2">3</h3>
```

## v-bind指令，设置一个元素的属性和自带属性值
```html
<h3 v-bind:class="class1" class="display-5"></h3>

...
computed: {
    class1(){
        return this.highlight ? ["bg-light", "text-dark","display-4"] : ["bg-dark", "text-light", "p-2"];
    }
}
...
```
- 该指令可以配置为一个变量或表达式。
- 当然也可以用对象或者数组配置class属性。
- 同时，其还会合并直接在元素上设置的class属性

```html
<h3 v-bind:style="elemStyles"></h3>

...
computed: {
    elemStyles(){
        return {
            "border": "5px solid red",
            "background-color": this.highlight ? "coral" : ""
        }
    }
}
...
```
- 也可以设置其他属性
- 当然也可以通过返回对象同时设置多个属性
- 设置html元素自带的属性值

```html
<h3 v-bind:text-content.prop="textContext"></h3>
```

