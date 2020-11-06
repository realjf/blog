---
title: "vue.js 2 系列之五 运动商店 A Real App"
date: 2020-11-06T16:41:21+08:00
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

## 准备
首先创建项目
```shell script
vue create sportsstore --default
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
### 添加附加包
```shell script
cd sportsstore
npm install axios@0.18.0
npm install vue-router@3.0.1
npm install vuex@3.0.1
npm install vuelidate@0.7.4
npm install font-awesome@4.7.0
npm install --save-dev json-server@0.12.1
npm install --save-dev jsonwebtoken@8.1.1
npm install --save-dev faker@4.1.0
```
- axios 提供http请求服务接口
- vue-router 提供浏览器端的路由服务
- vuex 提供应用内共享数据存储管理
- veulidate 提供用户输入数据验证服务
- bootstrap 提供css样式
- font-awesome 提供字体图标
- json-server 提供restful风格的web服务
- jsonwebtoken 用于生成认证token以获取授权
- faker 用于生产测试数据


### 添加样式到项目
在main.js中添加如下代码
```javascript
...
Vue.Config.productionTip = false
import "bootstrap/dist/css/bootstrap.min.css";
import "font-awesome/css/font-awesome.min.css";
...
```
### 准备restful web服务
在src/data.js下添加如下代码：
```javascript
var data = [
  {
    id: 1,
    name: "Kayak",
    category: "Watersports",
    description: "A boat for one person",
    price: 275,
  },
  {
    id: 2,
    name: "Lifejacket",
    category: "Watersports",
    description: "Protective and fashionable",
    price: 48.95,
  },
  {
    id: 3,
    name: "Soccer Ball",
    category: "Soccer",
    description: "FIFA-approved size and weight",
    price: 19.5,
  },
  {
    id: 4,
    name: "Corner Flags",
    category: "Soccer",
    description: "Give your playing field a professional touch",
    price: 34.95,
  },
  {
    id: 5,
    name: "Stadium",
    category: "Soccer",
    description: "Flat-packed 35,000-seat stadium",
    price: 79500,
  },
  {
    id: 6,
    name: "Thinking Cap",
    category: "Chess",
    description: "Improve brain efficiency by 75%",
    price: 16,
  },
  {
    id: 7,
    name: "Unsteady Chair",
    category: "Chess",
    description: "Secretly give your opponent a disadvantage",
    price: 29.95,
  },
  {
    id: 8,
    name: "Human Chess Board",
    category: "Chess",
    description: "A func game for the family",
    price: 75,
  },
  {
    id: 9,
    name: "Bling Bling King",
    category: "Chess",
    description: "Gold-plated, diamond-studded King",
    price: 1200,
  },
];

module.exports = function() {
  return {
    products: data,
    categories: [...new Set(data.map((p) => p.category))].sort(),
    orders: [],
  };
};

```
在src/authMiddleware.js文件里添加如下代码：
```javascript
const jwt = require("jsonwebtoken");

const APP_SECRET = "myappsecret";
const USERNAME = "admin";
const PASSWORD = "secret";

module.exports = function(req, res, next) {
  if (
    (req.url == "/api/login" || req.url == "/login") &&
    req.method == "POST"
  ) {
    if (
      req.body != null &&
      req.body.name == USERNAME &&
      req.body.password == PASSWORD
    ) {
      let token = jwt.sign({ data: USERNAME, expiresIn: "1h" }, APP_SECRET);
      res.json({ success: true, token: token });
    } else {
      res.json({ success: false });
    }
    res.end();
    return;
  } else if (
    ((req.url.startsWith("/api/products") ||
      req.url.startsWith("/products") ||
      req.url.startsWith("/api/categories") ||
        req.url.startsWith("/categories")) &&
      req.method != "GET") ||
    ((req.url.startsWith("/api/orders") || req.url.startsWith("/orders")) &&
      req.method != "POST")
  ) {
    let token = req.headers["authorization"];
    if (token != null && token.startsWith("Bearer<")) {
      token = token.substring(7, token.length - 1);
      try {
        jwt.verify(token, APP_SECRET);
        next();
        return;
      } catch (err) {}
    }
    res.statusCode = 401;
    res.end();
    return;
  }
  next();
};

```













