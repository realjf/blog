---
title: "vue.js 2 系列之十六 使用组件 Using Components"
date: 2020-11-30T10:14:57+08:00
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

- 为一个项目添加组件
- 使用props特性
- 使用自定义事件特性
- 使用slots（插槽）特性


## 理解组件作为构建块

组件是Vue.js应用的构建块，并且在一个应用中允许使用多个组件作为更小的功能单元，这些单元更易于编写、维护和重用整个应用程序

使用组件构建应用程序时，其效果是父子关系，其中组件（父组件）将其模板的一部分委托给另一个组件（子组件）。
最好的办法要了解这是如何工作的，需要创建一个示例来演示这种关系。组件是通常在src/components文件夹中扩展名为.vue的文件中定义，
并添加了一个叫Child.vue的文件在那个文件夹里


### 理解子组件命名和元素
我使用import语句中的名称来设置子组件，这导致了这个问题外观笨拙的自定义HTML元素
```html
<ChildComponent></ChildComponent>
```
这是一种有用的方法，可以证明父组件命名其子组件，但是Vue.js有一个更复杂的名称处理方法，这可以让其html更优雅。
当它查找要使用的子组件，第一命名的特点是Vue.js会自动格式化定义的html，

```html
<child-component></child-component>

...
import ChildComponent from "./components/Child";
components: {
    ChildComponent
}
...
```

#### 全局注册组件
在main.js中添加
```js
import ChildComponent from "./components/Child";

Vue.component("child-component", ChildComponent);
```

### 在子组件中使用组件特性
子组件也支持template元素，script元素，以及style元素。


## 理解组件隔离
组件之间是相互隔离的，这意味着您不必担心选择唯一的组件属性和方法名称，或绑定到由其他组件拥有的值。

#### 理解css的作用域

```html
<style scoped>

</style>
```
该scoped属性告诉Vue.js，样式应该纸杯应用在当前组件的template元素里的元素，而非其他组件里的元素。

### 使用组件props
保持组件隔离是一个很好的默认策略，因为它可以避免意外的交互。如果组件之间没有隔离，更改一个消息属性将影响所有部件。
另一方面，在大多数应用程序中，组件必须协同工作才能交付面向用户的特性，这意味着要突破分离组件的障碍。
对于组件协作来说有一个特点是，prop允许父级为子级提供数据值
```js
<script>
    export default {
    props: ["labelText"],
    data: function() {
    return {
    message: "this is a child component"
}
}
}
</script>
```
Props是使用分配给组件脚本中的Props属性的字符串数组定义的元素。在本例中，prop名称为labelText。一旦定义了prop，
就可以在组件中其他地方使用它，如在文本内插绑定。如果需要修改从父组件接收的值，则必须使用data或computed初始化从prop上获得的值
```js
<script>
    export default {
    props: ["labelText", "initialValue"],
    data: function() {
    return {
        message: this.initialValue
    }
    }
}
</script>
```

#### 在一个父组件中使用prop
当一个组件定义了一个prop时，它的父组件可以使用自定义的属性向它发送数据值HTML元素，如下，父组件内容
```html
<MyFeature labelText="Name" initialValue="Kayak"></MyFeature>
```
Vue.js在将属性名称匹配到prop时应用与匹配时相同的灵活性自定义HTML元素到组件。这意味着我可以使用labelText或label text来设置
prop

#### 使用prop值表达式
除非使用v-bind指令，否则Prop属性值不会作为表达式计算
```html
<my-feature v-bind:label-text="labelText" initial-value="Kayak"></my-feature>
```

### 创建自定义事件
```html
...
methods: {
    doSubmit() {
        this.$emit("productSubmit", this.product);
    }
}
...
```
使用this关键字调用的$emit方法用于发送自定义事件。第一个参数是事件类型，用字符串表示，可选的第二个参数是传递的数据，
它可以是父级可能发现有用的任何值。在这种情况下，我发送了一个名为productSubmit并将product对象作为有效负载

#### 从一个子组件接收一个自定义事件
父组件使用v-on指令从其子组件接收事件，就像常规DOM事件。我更新了应用程序vue文件，以便它提供子组件
使用要编辑的初始数据，并在触发时对其事件做出响应
```html
<my-feature v-bind:initial-product="product" v-on:productSubmit="updateProduct"></my-feature>

...
methods:{
    updateProduct(newProduct){
        this.message = JSON.stringify(newProduct);
    }
}
...
```

### 使用组件slots（插槽）
如果在应用程序的不同部分使用组件，则可能需要定制将元素呈现给用户以适应上下文。

对于简单的内容更改，可以使用prop，或者父组件可以直接设置自定义样式用于应用子组件的HTML元素。

对于更复杂的内容更改，Vue.js提供一个名为slots的功能，它允许父组件向子组件提供子组件自己提供内容显示的功能。

```html
<slot>
<h4>Use the form fields to edit the data</h4>
</slot>
```
slot元素表示组件模板的一个区域，该区域将被替换为父组件包含在用于应用子级的自定义元素的开始和结束标记之间组件。
如果父组件不提供任何内容，则Vue.js将忽略slot元素。

这提供了一个回退，允许子组件向用户显示有用的内容。到重写默认内容时，父组件必须在其模板中包含元素

#### 使用命名插槽

```html
<slot name="header"><h4>Use the form fields to edit the data</h4></slot>
<slot name="footer"></slot>
```
name属性用于为每个slot元素指定名称。在本例中，我将出现在输入元素上方的元素其命名为header，出现在它们下面的命名为footer
。页脚slot不包含任何元素，这意味着不会显示任何内容，除非父组件提供内容。
要使用命名的slot，父对象会将slot属性添加到自定义开始和结束标记

#### 使用作用域插槽（scoped slots）
作用域槽允许父组件提供子组件可以插入的模板数据，当子组件使用它执行转换时，这对于从父对象接收和父对象需要控制格式接收到的数据将很有用。

子组件定义模板内容：
```html
<slot v-bind:propname="prop" v-bind:propvalue="product[prop]"></slot>
{{prop}} : {{ product[prop]}}

...
export default {
    props: ["product"]
}

...
```

父组件传递数据给子组件

```html
<product-display v-bind:product="product">
<div slot-scope="data">
{{data.propname}} is {{data.propvalue}}
</div>
</product-display>
```
slot-scope属性用于选择模板将被处理的临时变量的名称，并且将为子级在其上定义的每个属性分配一个属性
slot元素，然后可以在slot内容中的数据绑定和指令中使用
