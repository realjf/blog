---
title: "vue.js 2 系列之十三 使用转发器指令 Using the Repeater Directive"
date: 2020-11-29T13:16:08+08:00
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

本节将介绍 

- v-for指令
- v-for指令的alias特性
- 用v-bind指令定义一个key属性
- 使用v-for指令的index特性
- 使用Vue.set方法
- 在v-for指令的表达式中使用data中预置的一个数值

## v-for指令，枚举一个数组
```html
...
<h2 class="bg-primary text-white text-center p-3">Products</h2>
<table class="table table-sm table-bordered table-striped text-left">
    <tr>
        <th>Name</th>
        <th>Price</th>
    </tr>
    <tbody>
        <tr v-for="p in products">
        <td>Name</td>
        <td>Category</td>
        </tr>
    </tbody>
</table>

...

...

data: function() {
    return {
        products: [
            {name: "Kayak", price: 275}
        ]
    }
}

...

```

### v-for指令的alias
```html
<h2 class="bg-primary text-white text-center p-3">Products</h2>
<table class="table table-sm table-bordered table-striped text-left">
    <tr>
        <th>Name</th>
        <th>Price</th>
    </tr>
    <tbody>
        <tr v-for="p in products" v-bind:key="p.name">
        <td>{{ p.name }}</td>
        <td>{{ p.price | currency }}</td>
        </tr>
    </tbody>
</table>

...

...

data: function() {
    return {
        products: [
            {name: "Kayak", price: 275},
            {name: "Lifejacket", price: 48.86},
            {name: "Soccer Ball", price: 19.50}
        ]
    }
},
filters: {
    currency(value){
        return new Intl.NumberFormat("en-US", {style: "currency", currency: "USD"}).format(value);
    },
},
...
```

### v-for指令下，定义key
默认情况下，v-for指令响应其处理的对象顺序的更改通过更新它所创建的每个元素所显示的内容。在这个例子中，这意味着
重新检查已创建的每个tr元素并更新td元素中包含的文本。向指令提供有关哪个对象与哪个元素相关的提示意味着选择
一个属性，并将其用作唯一键，然后使用v-bind指令标识该键。

v-bind指令用于设置名为key的属性，其值使用在v-for指令表达式中定义的alias表示。在本例中，我使用p作为v-for指令的alias，我想使用
name属性作为数据对象的键，因此我使用p.name作为v-bind表达式

### 获取v-for下一个项的索引

```html
<table class="table table-sm table-bordered table-striped text-left">
    <tr>
        <th>Index</th>
        <th>Name</th>
        <th>Price</th>
    </tr>
    <tbody>
        <tr v-for="(p, i) in products" v-bind:key="p.name" v-bind:odd="i%2==0">
        <td>{{ i+1 }}</td>
        <td>{{ p.name }}</td>
        <td>{{ p.price | currency }}</td>
        </tr>
    </tbody>
</table>

<style>
[odd]{ background-color: lightblue;}
</style>
```
 - i索引值从0开始
 
### 理解数组改变检测

#### 理解更新问题
有两种类型的数组改变，vue.js不能检测并且不会响应。

- 当一个数组项被替换时
- 当通过改变数组长度属性值缩短数组时

```html
<!-- 情况1 -->
handleClick() {
    this.products[1] = {name: "Running Shoes", price: 100};
}
```
解决方法是通过Vue.set方法进行设置。
```html
handleClick() {
    Vue.set(this.products, 1, {name: "Running Shoes", price: 100});
}
```
> Vue.set方法也能通过this.$set访问。

## 枚举对象自有属性
```html
<table class="table table-sm table-bordered table-striped text-left">
    <tr>
        <th>Index</th>
        <th>Name</th>
        <th>Price</th>
    </tr>
    <tbody>
        <tr v-for="(p, key, i) in products" v-bind:key="p.name" v-bind:odd="i%2==0">
        <td>{{ i+1 }}</td>
        <td>{{ p.name }}</td>
        <td>{{ p.price | currency }}</td>
        </tr>
    </tbody>
</table>

...
data: function() {
    return {
        products: {
            1: {name: "Kayak", price: 275},
            2: {name: "Lifejacket", price: 48.86},
            3: {name: "Soccer Ball", price: 19.50}
        }
    }
},
methods:{
    handleClick() {
        Vue.set(this.products, 4, {name: "Running Shoes", price: 100});
    }
}
...

```
当处理一个对象时，v-for指令提供了一个alias，一个包含了key的新变量，和一个索引变量。
当一个自有属性被修改时，Vue.js能检测到，但是当一个新的自有属性被添加到对象中时,Vue.js却不能提示，
这就是为什么使用Vue.set方法的原因。

### 理解对象自有属性排序
自有属性值是JS的Object.keys方法的按照一定顺序返回被枚举的，以下是通常自有属性值的排序如下：

1. 键是整数值的，包括能被转换成整数的，按照升序排列
2. 键是字符串的，按照它们定义的顺序排列
3. 所有其他键，按照它们定义的顺序排列

```html
<table class="table table-sm table-bordered table-striped text-left">
    <tr>
        <th>Index</th>
        <th>Key</th>
        <th>Name</th>
        <th>Price</th>
    </tr>
    <tbody>
        <tr v-for="(p, key, i) in products" v-bind:key="p.name" v-bind:odd="i%2==0">
        <td>{{ i+1 }}</td>
        <td>{{ key }}</td>
        <td>{{ p.name }}</td>
        <td>{{ p.price | currency }}</td>
        </tr>
    </tbody>
</table>

...
data: function() {
    return {
        products: {
            "realjf": {name: "realjf", price: 275},
            22: {name: "Kayak", price: 275},
            3: {name: "Lifejacket", price: 48.86},
            4: {name: "Soccer Ball", price: 19.50}
        }
    }
},
methods:{
    handleClick() {
        Vue.set(this.products, 5, {name: "Running Shoes", price: 100});
    }
}
...
```
其排序结果的key值依次时：3, 4, 5, 22, realjf

## 重复没有数据源的HTML元素

```html
<table class="table table-sm table-bordered table-striped text-left">
    <tr>
        <th>Index</th>
        <th>Key</th>
        <th>Name</th>
        <th>Price</th>
    </tr>
    <tbody>
        <tr v-for="(p, key, i) in products" v-bind:key="p.name" v-bind:odd="i%2==0">
        <td>{{ i+1 }}</td>
        <td>{{ key }}</td>
        <td>{{ p.name }}</td>
        <td>{{ p.price | currency }}</td>
        </tr>
    </tbody>
</table>
<div class="text-center">
    <button v-for="i in 5" v-on:click="handleClick(i)" class="btn btn-primary m-2">{{i}}</button>
</div>
```
上面的button中的v-for指令将生成5格按钮，并且其按钮文本依次显示 1, 2, 3, 4, 5


## 使用计算属性值与v-for指令

### 分页数据
```html
<button v-for="i in pageCount" v-on:click="selectPage(i)" class="btn btn-secondary m-1" v-bind:class="{'bg-primary': currentPage == i}">{{i}}</button>

...
data: function() {
    return {
        pageSize: 3,
        currentPage: 1,
        products: [
            {name: "realjf", price: 275},
            {name: "Kayak", price: 275},
            {name: "Lifejacket", price: 48.86},
            {name: "Soccer Ball", price: 19.50}
        ]
    }
},
computed: {
    pageCount(){
        return Math.ceil(this.products.length / this.pageSize);
    },
    pageItems() {
        let start = (this.currentPage -1) * this.pageSize;
        return this.products.slice(start, start+this.pageSize);
    }
},
methods:{
    selectPage(page){
        this.currentPage = page;
    }
}
...
```

### 数据过滤和排序

在计算属性值返回前可以对其进行排序和过滤。





