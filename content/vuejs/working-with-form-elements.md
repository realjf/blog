---
title: "vue.js 2 系列之十五 为表单元素工作 Working With Form Elements"
date: 2020-11-29T15:40:26+08:00
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


本节将学习：

- 使用v-model指令
- 使用number修饰符
- 使用lazy修饰符
- 使用trim修饰符
- 使用v-model指令绑定数组
- 使用v-model指令自定义数值
- 使用v-model指令验证收集的表单数据


## 创建双向模型绑定
- 到目前为止，我所创建的所有数据绑定是单向的，其意味着数据流从组件的script元素到template元素都能对用户展示。
- 当表单元素是应用程序唯一改变源时双向数据绑定能正常工作。当用户有其他方法进行更改（如重置）时，它们的效果会降低，
其v-on指令调用reset方法，该方法将dataValue设置为false。这个文本插值绑定正确地反映了新值，但是输入元素没有意识到这个变化变得不同步

### 添加一个双向绑定
表单元素需要数据流的双向的，数据必须在用户操纵元素时，从表单流向数据模型。
如当输入一个域值或勾选复选框时。当数据模型被其他有意义的修改时，数据也必须从反向流动。以确保始终向用户提供一致的数据。

```html
<input class="form-check-input" type="checkbox" v-on:change="handleChange" v-bind:checked="dataValue" />
```

使用v-bind指令设置元素的checked属性值，确保点击按钮能影响到checkbox

现在有双向绑定在dataValue属性和checkbox间形成

### 添加另外一个input元素
表单元素的HTML和DOM规范不一致，并且在方式上存在差异必须在用于创建的v-on和v-bind指令中反映不同的元素类型双向数据绑定

```html
<div class="bg-primary m-2 p-2">
    <input type="text" class="form-control" v-on:input="handleChange" v-bind:value="otherValue"/>
</div>
```
这个例子显示了为不同类型元素创建双向绑定的要求不同。当处理checkbox时，我们必须监听change事件，并绑定到checked属性，
但是对于text input元素，我们监听的是input时间，并绑定value属性。

### 简化双向绑定
创建绑定所需的差异使设置绑定的过程复杂化，并且很容易混淆不同元素类型的需求，最终使用错误的事件、属性或自有属性

Vue.js提供了v-model指令，它简化了双向绑定，自动处理不同元素的不同要求，其能处理如：input,select,textarea等元素

```html
<input class="form-check-input" type="checkbox" v-model="dataValue" />
```


## 绑定表单元素

### 绑定text域
最简单的绑定是为配置为允许用户输入文本的输入元素创建的。我使用了为纯文本和密码设置的输入元素，以及使用v-model的双向绑定
指令
```html
<div>Name: {{ name }}</div>
<div>Password: {{ password }}</div>
<input type="text" v-model="name">
<input type="password" v-model="password">
```
### 绑定单选按钮和复选框

```html
<div>Name: {{ name }}</div>
<div>Password: {{ password }}</div>
<input type="radio" v-model="name" value="Bob">
<input type="radio" v-model="name" value="Alice">
<input type="checkbox" v-model="hasAdminAccess">
```

### 绑定select元素
```html
<select v-model="name">

</select>
```

## 使用v-model修饰符
v-model指令提供了3种绑定，这些修饰符如下：

| 修饰符| 描述|
|:---:|:---:|
| number | 此修饰符将输入中的值解析为数字，然后将其分配给数据属性|
| trim | 此修饰符在赋值之前从输入中删除所有前导空格和尾随空格数据属性|
| lazy | 此修饰符更改v-model指令侦听的事件，以便属性仅在用户导航离开输入元素时更新|

### 格式化数值
number修饰符解决了设置type属性为number时input元素工作方式的一个奇怪之处

```html
<input type="number" v-model="amount">
```

### 延迟更新
默认情况下，v-model指令在每次按键进入input或textarea之后更新数据模型元素。
lazy修饰符更改v-model指令侦听的事件，以便更新仅当导航到其他组件时执行。
```html
<input type="number" v-model.number.lazy="amount">
```

### 移除空格字符
trim修饰符从用户输入的文本移除前导和尾随空格字符
```html
<input type="text" v-model.trim="name">
```

## 绑定不同数据类型

### 选择一个数组项
如果v-model指令应用于复选框并绑定到作为数组的数据属性，则检查取消选中该框将在数组中添加或删除一个值。

```html
<div v-for="city in cityNames" v-bind:key="city">
<input type="checkbox" v-model="cites" v-bind:value="city">
</div>
```
其中的cites是一个数组。

#### 使用一个select元素绑定一个数组

```html
<select multiple v-model="cities">
<option v-for="city in cityNames" v-bind:key="city"></option>
</select>
```

### 为表单元素添加自定义数据

#### 为radio按钮和select元素使用自定义值
```html
<input type="checkbox" v-model="dataValue" v-bind:true-value="darkColor" v-bind:false-value="lightColor">
```

## 验证表单数据

表单验证前需要对表单元素做些修改

```html
<form v-on:submit.prevent="handleSubmit"></form>
```

| 名字| 描述 |
| name | 该用户必须提供一个包含至少3个字符的值|
| category| 该用户必须提供一个包含只有字符的值|
| price| 该用户必须提供一个包含只有数字的值，且在1~1000内|

### 定义一个验证规则

### 演示验证

### 实时响应变更






