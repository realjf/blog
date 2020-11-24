---
title: "vue.js 2 系列之五 运动商店 A Real App"
date: 2020-11-06T16:41:21+08:00
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
在sportsstore/data.js下添加如下代码：
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
在sportsstore/authMiddleware.js文件里添加如下代码：
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
在package.json中添加如下内容
```javascript
"scripts": {
    "json": "json-server data.js -p 3500 -m authMiddleware.js"
}
```

运行web 服务
```shell script
npm run json
```
在第二个终端中执行一下命令
```shell script
npm run serve
```

### 创建数据存储
在src/store文件夹下添加index.js文件，内容如下：
```javascript
import Vue from "vue";
import Vuex from "vuex";

Vue.use(Vuex);

const testData = [];

for(let i = 1; i <= 10; i++){
    testData.push({
        id: i, name: `Product #${i}`, category: `Category ${i % 3}`,
        description: `This is Product #${i}`, price: i * 50
    })
}

export default new Vuex.Store({
    strict: true,
    state: {
        products: testData
    }
})

```

添加vuex数据存储，在src/main.js中添加内容
```javascript
import Vue from 'vue'
import App from './App.vue'

// 引入jquery
import $ from 'jquery'

Vue.config.productionTip = false

// 添加bootstrap框架
import "bootstrap/dist/css/bootstrap.min.css";
import "font-awesome/css/font-awesome.min.css";

// 添加vuex存储
import store from "./store";

new Vue({
  render: h => h(App),
  store // 挂在岛vue中
}).$mount('#app')

```

## 创建项目存储
在src/components文件夹下新建Store.vue文件，其内容如下：
```html
<template>
<div class="container-fluid">
    <div class="row">
        <div class="col bg-dark text-white">
            <a class="navbar-brand">SPORTS STORE</a>
        </div>
    </div>
    <div class="row">
        <div class="col-3 bg-info p-2">
            <h4 class="text-white m-2">Categories</h4>
        </div>
        <div class="col-9 bg-success p-2">
            <h4 class="text-white m-2">Products</h4>
        </div>
    </div>
</div>
</template>

```

然后在App.vue文件中修改为如下内容：
```html
<template>
<store />
</template>

<script>
import Store from './components/Store'

export default {
    name: 'App',
    components: {
        Store
    }
}
</script>

<style>
#app {
    font-family: Avenir, Helvetica, Arial, sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    text-align: center;
    color: #2c3e50;
    margin-top: 60px;
}
</style>

```
需要先引入组件文件，然后在export default里的components里添加组件，最后在template模板标签中添加相应的组件元素即可

当vue.js处理组件模板时，会使用组件的模板文件替换相应的组件元素标签


## 创建产品列表
在src/components文件夹中添加ProductList.vue文件，其内容如下
```html
<template>
<div>
    <div v-for="p in products" v-bind:key="p.id" class="card m-1 p-1 bg-light">
        <h4>
            {{p.name}}
            <span class="badge badge-pill badge-primary float-right">
                {{p.price}}
            </span>
        </h4>
        <div class="card-text bg-white p-1">{{p.description}}</div>
    </div>
</div>
</template>

<script>
import {
    mapState
} from "vuex";

export default {
    computed: {
        ...mapState(["products"])
    },
}
</script>

```

### 添加产品列表到应用

在src/components文件夹的Store.vue文件中注册组件
```html
<template>
<div class="container-fluid">
    <div class="row">
        <div class="col bg-dark text-white">
            <a class="navbar-brand">SPORTS STORE</a>
        </div>
    </div>
    <div class="row">
        <div class="col-3 bg-info p-2">
            <h4 class="text-white m-2">Categories</h4>
        </div>
        <div class="col-9 p-2">
            <!-- 使用注册组件 -->
            <product-list />
        </div>
    </div>
</div>
</template>

<script>
// 导入组件文件
import ProductList from "./ProductList"
export default {
    components: {
        ProductList // 注册组件
    }
}
</script>

```
### 过滤价格数据
在src/components文件夹的ProductList.vue文件中添加如下内容
```html
<template>
<div>
    <div v-for="p in products" v-bind:key="p.id" class="card m-1 p-1 bg-light">
        <h4>
            {{p.name}}
            <span class="badge badge-pill badge-primary float-right">
                {{p.price | currency}} <!--使用过滤函数 -->
            </span>
        </h4>
        <div class="card-text bg-white p-1">{{p.description}}</div>
    </div>
</div>
</template>

<script>
import {
    mapState
} from "vuex";

export default {
    computed: {
        ...mapState(["products"])
    },
    // 添加过滤函数
    filters: {
        currency(value) {
            return new Intl.NumberFormat("en-US", {
                style: "currency",
                currency: "USD"
            }).format(value);
        }
    }
}
</script>

```
使用过滤函数通过通道|（竖线）进行传递数据

### 添加产品分页
在src/store文件夹的index.js文件中进行分页
```javascript
import Vue from "vue";
import Vuex from "vuex";

Vue.use(Vuex);

const testData = [];

for(let i = 1; i <= 10; i++){
    testData.push({
        id: i, name: `Product #${i}`, category: `Category ${i % 3}`,
        description: `This is Product #${i}`, price: i * 50
    })
}

export default new Vuex.Store({
    strict: true,
    state: {
        products: testData,
        productsTotal: testData.length,
        currentPage: 1,
        pageSize: 4
    },
    getters: {
        // 根据当前分页以及每页个数返回当前页面产品列表
        processedProducts: state => {
            let index = (state.currentPage - 1) * state.pageSize;
            return state.products.slice(index, index + state.pageSize);
        },
        // 计算分页总数
        pageCount: state => Math.ceil(state.productsTotal / state.pageSize)
    },
    mutations: {
        // 设置当前分页
        setCurrentPage(state, page){
            state.currentPage = page;
        },
        // 设置每页个数
        setPageSize(state, size){
            state.pageSize = size;
            state.currentPage = 1;
        }
    }
})


```
- mutations 时一个改变数据方法的集合


接下来在src/components文件夹中添加文件PageControls.vue文件，其内容如下：
```html
<template>
  <div v-if="pageCount > 1" class="text-right">
    <div class="btn-group mx-2">
      <button
        v-for="i in pageNumbers"
        v-bind:key="i"
        class="btn btn-secpmdary"
        v-bind:class="{ 'btn-primary': i == currentPage }"
      >
        {{ i }}
      </button>
    </div>
  </div>
</template>

<script>
import { mapState, mapGetters } from "vuex";

export default {
  computed: {
    ...mapState(["currentPage"]),
    ...mapGetters(["pageCount"]),
    pageNumbers() {
      return [...Array(this.pageCount + 1).keys()].slice(1);
    },
  },
};
</script>

```
然后在src/components文件夹中的ProductList.vue文件中使用分页
```html
<template>
<div>
    <div v-for="p in products" v-bind:key="p.id" class="card m-1 p-1 bg-light">
        <h4>
            {{p.name}}
            <span class="badge badge-pill badge-primary float-right">
                <!--使用过滤函数 -->
                {{p.price | currency}}
            </span>
        </h4>
        <div class="card-text bg-white p-1">{{p.description}}</div>
    </div>
 <page-controls />
</div>
</template>

<script>
import {
    mapGetters
} from "vuex";
import PageControls from "./PageControls";

export default {
    components: {
        PageControls
    },
    computed: {
        ...mapGetters({
            products: "processedProducts"
        })
    },
    // 添加过滤函数
    filters: {
        currency(value) {
            return new Intl.NumberFormat("en-US", {
                style: "currency",
                currency: "USD"
            }).format(value);
        }
    }
}
</script>

```
### 切换产品页面
在src/components文件夹中的PageControls.vue文件中添加如下内容：
```html
<template>
<div v-if="pageCount > 1" class="text-right">
    <div class="btn-group mx-2">
        <!-- 使用v-on指令绑定点击事件 -->
        <button v-for="i in pageNumbers" v-bind:key="i" class="btn btn-secpmdary" v-bind:class="{ 'btn-primary': i == currentPage }" v-on:click="setCurrentPage(i)">
            {{ i }}
        </button>
    </div>
</div>
</template>

<script>
import {
    mapState,
    mapGetters,
    mapMutations
} from "vuex";

export default {
    computed: {
        ...mapState(["currentPage"]),
        ...mapGetters(["pageCount"]),
        pageNumbers() {
            return [...Array(this.pageCount + 1).keys()].slice(1);
        },
    },
    methods: {
        ...mapMutations(["setCurrentPage"])
    }
};
</script>

```

### 改变每页个数
在src/components文件夹的PageControls.vue文件中添加如下内容：
```html
<template>
<div class="row mt-2">
    <div class="col form-group">
        <select class="form-control" v-on:change="changePageSize">
            <option value="4">4 per page</option>
            <option value="8">8 per page</option>
            <option value="12">12 per page</option>
        </select>
    </div>
    <div class="text-right col">
        <div class="btn-group mx-2">
            <!-- 使用v-on指令绑定点击事件 -->
            <button v-for="i in pageNumbers" v-bind:key="i" class="btn btn-secpmdary" v-bind:class="{ 'btn-primary': i == currentPage }" v-on:click="setCurrentPage(i)">
                {{ i }}
            </button>
        </div>
    </div>
</div>
</template>

<script>
import {
    mapState,
    mapGetters,
    mapMutations
} from "vuex";

export default {
    computed: {
        ...mapState(["currentPage"]),
        ...mapGetters(["pageCount"]),
        pageNumbers() {
            return [...Array(this.pageCount + 1).keys()].slice(1);
        },
    },
    methods: {
        ...mapMutations(["setCurrentPage", "setPageSize"]),
        changePageSize($event) {
            this.setPageSize(Number($event.target.value));
        }
    }
};
</script>

```
### 添加分类选项
在src/store文件夹中index.js中添加如下内容：
```javascript
import Vue from "vue";
import Vuex from "vuex";

Vue.use(Vuex);

const testData = [];

for(let i = 1; i <= 10; i++){
    testData.push({
        id: i, name: `Product #${i}`, category: `Category ${i % 3}`,
        description: `This is Product #${i}`, price: i * 50
    })
}

export default new Vuex.Store({
    strict: true,
    state: {
        products: testData,
        productsTotal: testData.length,
        currentPage: 1,
        pageSize: 4,
        currentCategory: "All"
    },
    getters: {
        productsFilteredByCategory: state => state.products.filter(p => state.currentCategory == "All" || p.category == state.currentCategory),
        // 根据当前分页以及每页个数返回当前页面产品列表
        processedProducts: (state, getters) => {
            let index = (state.currentPage - 1) * state.pageSize;
            return getters.productsFilteredByCategory.slice(index, index + state.pageSize);
        },
        // 计算分页总数
        pageCount: (state, getters) => Math.ceil(getters.productsFilteredByCategory.length / state.pageSize),
        categories: state => ["All", ...new Set(state.products.map(p => p.category).sort())]
    },
    mutations: {
        // 设置当前分页
        setCurrentPage(state, page){
            state.currentPage = page;
        },
        // 设置每页个数
        setPageSize(state, size){
            state.pageSize = size;
            state.currentPage = 1;
        },
        // 设置当前分类
        setCurrentCategory(state, category){
            state.currentCategory = category;
            state.currentPage = 1;
        }
    }
})

```

在src/components文件夹中添加CategoryControls.vue文件，其内容如下：
```html
<template>
<div class="container-fluid">
    <div class="row my-2" v-for="c in categories" v-bind:key="c">
        <button class="btn btn-block" v-on:click="setCurrentCategory(c)" v-bind:class="c == currentCategory ? 'btn-primary' : 'btn-secondary'">
            {{c}}
        </button>
    </div>
</div>
</template>

<script>
import {
    mapState,
    mapGetters,
    mapMutations
} from "vuex";
export default {
    computed: {
        ...mapState(["currentCategory"]),
        ...mapGetters(["categories"])
    },
    methods: {
        ...mapMutations(["setCurrentCategory"])
    }
}
</script>

```

在src/components文件夹的Store.vue中添加分类选择
```html
<template>
<div class="container-fluid">
    <div class="row">
        <div class="col bg-dark text-white">
            <a class="navbar-brand">SPORTS STORE</a>
        </div>
    </div>
    <div class="row">
        <div class="col-3 bg-info p-2">
            <!-- 使用分类组件 -->
            <CategoryControls />
        </div>
        <div class="col-9 p-2">
            <!-- 使用注册组件 -->
            <product-list />
        </div>
    </div>
</div>
</template>

<script>
// 导入组件文件
import ProductList from "./ProductList"
import CategoryControls from "./CategoryControls";
export default {
    components: {
        ProductList,
        CategoryControls
    }
}
</script>

```

## 使用RESTful web服务

在src/store文件夹的index.js文件中添加如下内容
```javascript
import Vue from "vue";
import Vuex from "vuex";

import Axios from "axios";

Vue.use(Vuex);

const baseUrl = "http://localhost:3500";
const productsUrl = `${baseUrl}/products`;
const categoriesUrl = `${baseUrl}/categories`;

const testData = [];

for(let i = 1; i <= 10; i++){
    testData.push({
        id: i, name: `Product #${i}`, category: `Category ${i % 3}`,
        description: `This is Product #${i}`, price: i * 50
    })
}

export default new Vuex.Store({
    strict: true,
    state: {
        products: testData,
        categoriesData: [],
        productsTotal: testData.length,
        currentPage: 1,
        pageSize: 4,
        currentCategory: "All"
    },
    getters: {
        productsFilteredByCategory: state => state.products.filter(p => state.currentCategory == "All" || p.category == state.currentCategory),
        // 根据当前分页以及每页个数返回当前页面产品列表
        processedProducts: (state, getters) => {
            let index = (state.currentPage - 1) * state.pageSize;
            return getters.productsFilteredByCategory.slice(index, index + state.pageSize);
        },
        // 计算分页总数
        pageCount: (state, getters) => Math.ceil(getters.productsFilteredByCategory.length / state.pageSize),
        categories: state => ["All", ...state.categoriesData]
    },
    mutations: {
        // 设置当前分页
        setCurrentPage(state, page){
            state.currentPage = page;
        },
        // 设置每页个数
        setPageSize(state, size){
            state.pageSize = size;
            state.currentPage = 1;
        },
        // 设置当前分类
        setCurrentCategory(state, category){
            state.currentCategory = category;
            state.currentPage = 1;
        },
        setData(state, data){
            state.products = data.pdata;
            state.productsTotal = data.pdata.length;
            state.categoriesData = data.cdata.sort();
        }
    },
    actions: {
        async GamepadHapticActuator(context) {
            let pdata = (await Axios.get(productsUrl)).data;
            let cdata = (await Axios.get(categoriesUrl)).data;
            context.commit("setData", {pdata, cdata});
        }
    }
})

```
在App.vue中添加如下内容：
```html
<template>
<store />
</template>

<script>
import Store from './components/Store';
import {
    mapActions
} from "vuex";

export default {
    name: 'App',
    components: {
        Store
    },
    methods: {
        ...mapActions({
            getData: "getData"
        })
    },
    created() {
        this.getData();
    }
}
</script>

<style>
#app {
    font-family: Avenir, Helvetica, Arial, sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    text-align: center;
    color: #2c3e50;
    margin-top: 60px;
}
</style>


```





