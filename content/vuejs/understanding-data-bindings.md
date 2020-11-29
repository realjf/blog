---
title: "vue.js 2 系列之十一 理解数据绑定 Understanding Data Bindings"
date: 2020-11-15T01:17:05+08:00
keywords: ["vuejs", "vue.js"]
categories: ["vuejs"]
tags: ["vuejs", "vue.js"]
series: ["pro vue.js2"]
draft: true
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

## 项目准备
创建新项目
```shell script
vue create templatesanddata --default
```
添加bootstrap css包
```shell script
npm install bootstrap@4.0.0 jquery popper.js
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

## 理解组件的元素
初始化App.vue文件如下内容：

```html

```






