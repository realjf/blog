---
title: "vue.js 2 系列之十七 理解组件生命周期 Understanding the Component Lifecycle"
date: 2020-12-08T22:49:25+08:00
keywords: ["vuejs", "vue.js"]
categories: ["vuejs"]
tags: ["vuejs", "vue.js"]
series: ["pro vue.js2"]
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

## 准备
```shell script
vue create lifecycles --default
```
安装jquery，bootstrap，popper.js
```shell script
cd sportsstore
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

## 理解组件生命周期

组件生命周期方法

|名称| 描述|
|:---:|:---:|
|beforeCreate| 此方法在Vue.js初始化组件之前被调用|
|created| Vue.js初始化组件后将调用此方法|
|beforeMount| 在Vue.js处理组件的模板之前|
|mounted| Vue.js处理组件的模板后将调用此方法。|
|beforeUpdate| 在Vue.js处理组件数据的更新之前|
|updated |在Vue.js处理组件数据的更新后，将调用此方法|
|activated| 当激活了一个通过keep-alive元素保持活动的组件时，将调用此方法|
|deactivated| 当停用通过keep-alive元素保持活动的组件时，将调用此方法 |
|beforeDestroy| 此方法在Vue.js销毁组件之前被调用。|
|destroyed| 在Vue.js销毁组件之后，将调用此方法|
|errorCaptured| 此方法允许组件处理其子项之一引发的错误|


### 理解创建
src/App.vue内容如下：
```html
<template>
<div class="bg-primary text-white m-2 p-2">
<div class="form-check">
<input class="form-check-input" type="checkbox" v-model="checked" />
<label>Checkbox</label>
</div>
Checked Value: {{ checked }}
</div>
</template>
<script>
export default {
name: 'App',
data: function () {
return {
checked: true
}
},
beforeCreate() {
console.log("beforeCreate method called" + this.checked);
},
created() {
console.log("created method called" + this.checked);
}
}
</script>
```

### 理解 mounting



