---
title: "vue.js 2 系列之七 运动商店 A Real App 3"
date: 2020-11-07T14:35:06+08:00
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

## 基于之前一篇基础之上进行构建
[/vuejs/a-real-app-2/](/vuejs/a-real-app-2/)


## 准备
在data.js文件中添加如下内容：
```javascript
var faker = require("faker");

var data = [];
var categories = ["Watersports", "Soccer","Chess", "Running"];

faker.seed(100);

for(let i=1; i<=500; i++){
  var category = faker.helpers.randomize(categories);
  data.push({
    id: i,
    name: faker.commerce.productName(),
    category: category,
    description: `${category}: ${faker.lorem.sentence(3)}`,
    price: faker.commerce.price()
  })
}

module.exports = function() {
  return {
    products: data,
    categories: categories,
    orders: [],
  };
};

```


然后执行如下命令：
```shell script
npm run json
```
在另外一个终端执行如下命令：
```shell script
npm run serve
```

## 处理大量数据

### 改进分页导航

在src/components文件夹的PageControls.vue文件中添加如下内容：
```html
<template>
<div class="row mt-2">
    <div class="col-3 form-group">
        <select class="form-control" v-on:change="changePageSize">
            <option value="4">4 per page</option>
            <option value="8">8 per page</option>
            <option value="12">12 per page</option>
        </select>
    </div>
    <div class="text-right col">
        <button v-bind:disabled="currentPage==1" v-on:click="setCurrentPage(currentPage-1)" class="btn btn-secondary mx-1">
            Previous
        </button>
        <span v-if="currentPage > 4">
            <button v-on:click="setCurrentPage(1)" class="btn btn-secondary mx-1">1</button>
            <span class="h4">...</span>
        </span>
        <span class="mx-1">
            <button v-for="i in pageNumbers" v-bind:key="i" class="btn btn-secpmdary" v-bind:class="{'btn-primary': i ==currentPage }" v-on:click="setCurrentPage(i)">
                {{i}}
            </button>
        </span>
        <span v-if="currentPage <= pageCount - 4">
            <span class="h4">...</span>
            <button v-on:click="setCurrentPage(pageCount)" class="btn btn-secondary mx-1">{{pageCount}}</button>
        </span>
        <button v-bind:disabled="currentPage==pageCount" v-on:click="setCurrentPage(currentPage+1)" class="btn btn-secondary mx-1">Next</button>
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
// 页码设置
        pageNumbers() {
            if (this.pageCount < 4) {
                return [...Array(this.pageCount + 1).keys()].slice(1);
            } else if (this.currentPage <= 4) {
                return [1, 2, 3, 4, 5];
            } else if (this.currentPage > this.pageCount - 4) {
                return [...Array(5).keys()].reverse().map(v => this.pageCount - v);
            } else {
                return [this.currentPage - 1, this.currentPage, this.currentPage + 1];
            }
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

### 减少应用请求数据量
在src/store文件夹的index.js文件中添加如下内容：
```javascript
import Vue from "vue";
import Vuex from "vuex";

import Axios from "axios";
import CartModule from "./cart";
import OrdersModule from "./orders";

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
    modules: {cart: CartModule, orders: OrdersModule }, // 添加购物车模块
    state: {
        // products: testData,
        categoriesData: [],
        // productsTotal: testData.length,
        currentPage: 1,
        pageSize: 4,
        currentCategory: "All",
        pages: [],
        serverPageCount: 0
    },
    getters: {
        // productsFilteredByCategory: state => state.products.filter(p => state.currentCategory == "All" || p.category == state.currentCategory),
        // 根据当前分页以及每页个数返回当前页面产品列表
        processedProducts: (state) => {
            return state.pages[state.currentPage];
        },
        // 计算分页总数
        pageCount: (state) => state.serverPageCount,
        categories: state => ["All", ...state.categoriesData]
    },
    mutations: {
        // 设置当前分页
        _setCurrentPage(state, page){
            state.currentPage = page;
        },
        // 设置每页个数
        _setPageSize(state, size){
            state.pageSize = size;
            state.currentPage = 1;
        },
        // 设置当前分类
        _setCurrentCategory(state, category){
            state.currentCategory = category;
            state.currentPage = 1;
        },
        // setData(state, data){
        //     state.products = data.pdata;
        //     state.productsTotal = data.pdata.length;
        //     state.categoriesData = data.cdata.sort();
        // },
        addPage(state, page){
            for(let i=0; i<page.pageCount; i++){
                Vue.set(state.pages, page.number +i, page.data.slice(i*state.pageSize, (i*state.pageSize) + state.pageSize));
            }
        },
        clearPages(state){
            state.pages.splice(0, state.pages.length);
        },
        setCategories(state, categories){
            state.categoriesData = categories;
        },
        setPageCount(state, count){
            state.serverPageCount = Math.ceil(Number(count)/state.pageSize);
        }
    },
    actions: {
        async getData(context) {
            await context.dispatch("getPage", 2);
            context.commit("setCategories", (await Axios.get(categoriesUrl)).data);
        },
        async getPage(context, getPageCount = 1){
            let url = `${productsUrl}?_page=${context.state.currentPage}` + `&_limit=${context.state.pageSize * getPageCount}`;
            if(context.state.currentCategory != "All"){
                url += `&category=${context.state.currentCategory}`;
            }
            let response = await Axios.get(url);
            context.commit("setPageCount", response.headers["x-total-count"]);
            context.commit("addPage", {number: context.state.currentPage, data: response.data, pageCount: getPageCount});
        },
        setCurrentPage(context, page){
            context.commit("_setCurrentPage", page);
            if(!context.state.pages[page]){
                context.dispatch("getPage");
            }
        },
        setPageSize(context, size){
            context.commit("clearPages");
            context.commit("_setPageSize", size);
            context.dispatch("getPage", 2);
        },
        setCurrentCategory(context, category){
            context.commit("clearPages");
            context.commit("_setCurrentCategory", category);
            context.dispatch("getPage", 2);
        }
    }
})


```

#### 更新组件使其用actions
在src/components文件夹中的CategoryControls.vue文件中添加如下内容：
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
    mapActions
} from "vuex";
export default {
    computed: {
        ...mapState(["currentCategory"]),
        ...mapGetters(["categories"])
    },
    methods: {
        ...mapActions(["setCurrentCategory"])
    }
}
</script>

```
使用actions更新src/components文件夹中的PageControls.vue文件中
```html
<template>
<div class="row mt-2">
    <div class="col-3 form-group">
        <select class="form-control" v-on:change="changePageSize">
            <option value="4">4 per page</option>
            <option value="8">8 per page</option>
            <option value="12">12 per page</option>
        </select>
    </div>
    <div class="text-right col">
        <button v-bind:disabled="currentPage==1" v-on:click="setCurrentPage(currentPage-1)" class="btn btn-secondary mx-1">
            Previous
        </button>
        <span v-if="currentPage > 4">
            <button v-on:click="setCurrentPage(1)" class="btn btn-secondary mx-1">1</button>
            <span class="h4">...</span>
        </span>
        <span class="mx-1">
            <button v-for="i in pageNumbers" v-bind:key="i" class="btn btn-secpmdary" v-bind:class="{'btn-primary': i ==currentPage }" v-on:click="setCurrentPage(i)">
                {{i}}
            </button>
        </span>
        <span v-if="currentPage <= pageCount - 4">
            <span class="h4">...</span>
            <button v-on:click="setCurrentPage(pageCount)" class="btn btn-secondary mx-1">{{pageCount}}</button>
        </span>
        <button v-bind:disabled="currentPage==pageCount" v-on:click="setCurrentPage(currentPage+1)" class="btn btn-secondary mx-1">Next</button>
    </div>
</div>
</template>

<script>
import {
    mapState,
    mapGetters,
    mapActions
} from "vuex";

export default {
    computed: {
        ...mapState(["currentPage"]),
        ...mapGetters(["pageCount"]),
        pageNumbers() {
            if (this.pageCount < 4) {
                return [...Array(this.pageCount + 1).keys()].slice(1);
            } else if (this.currentPage <= 4) {
                return [1, 2, 3, 4, 5];
            } else if (this.currentPage > this.pageCount - 4) {
                return [...Array(5).keys()].reverse().map(v => this.pageCount - v);
            } else {
                return [this.currentPage - 1, this.currentPage, this.currentPage + 1];
            }
        },
    },
    methods: {
        ...mapActions(["setCurrentPage", "setPageSize"]),
        changePageSize($event) {
            this.setPageSize(Number($event.target.value));
        }
    }
};
</script>

```

### 添加搜索支持

在src/store文件夹的index.js文件中添加如下代码:
```javascript
import Vue from "vue";
import Vuex from "vuex";

import Axios from "axios";
import CartModule from "./cart";
import OrdersModule from "./orders";

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
    modules: {cart: CartModule, orders: OrdersModule }, // 添加购物车模块
    state: {
        // products: testData,
        categoriesData: [],
        // productsTotal: testData.length,
        currentPage: 1,
        pageSize: 4,
        currentCategory: "All",
        pages: [],
        serverPageCount: 0,
        searchTerm: "",
        showSearch: false
    },
    getters: {
        // productsFilteredByCategory: state => state.products.filter(p => state.currentCategory == "All" || p.category == state.currentCategory),
        // 根据当前分页以及每页个数返回当前页面产品列表
        processedProducts: (state) => {
            return state.pages[state.currentPage];
        },
        // 计算分页总数
        pageCount: (state) => state.serverPageCount,
        categories: state => ["All", ...state.categoriesData]
    },
    mutations: {
        // 设置当前分页
        _setCurrentPage(state, page){
            state.currentPage = page;
        },
        // 设置每页个数
        _setPageSize(state, size){
            state.pageSize = size;
            state.currentPage = 1;
        },
        // 设置当前分类
        _setCurrentCategory(state, category){
            state.currentCategory = category;
            state.currentPage = 1;
        },
        // setData(state, data){
        //     state.products = data.pdata;
        //     state.productsTotal = data.pdata.length;
        //     state.categoriesData = data.cdata.sort();
        // },
        addPage(state, page){
            for(let i=0; i<page.pageCount; i++){
                Vue.set(state.pages, page.number +i, page.data.slice(i*state.pageSize, (i*state.pageSize) + state.pageSize));
            }
        },
        clearPages(state){
            state.pages.splice(0, state.pages.length);
        },
        setCategories(state, categories){
            state.categoriesData = categories;
        },
        setPageCount(state, count){
            state.serverPageCount = Math.ceil(Number(count)/state.pageSize);
        },
        setShowSearch(state, show){
            state.showSearch = show;
        },
        setSearchTerm(state, term){
            state.searchTerm = term;
            state.currentPage = 1;
        }
    },
    actions: {
        async getData(context) {
            await context.dispatch("getPage", 2);
            context.commit("setCategories", (await Axios.get(categoriesUrl)).data);
        },
        async getPage(context, getPageCount = 1){
            let url = `${productsUrl}?_page=${context.state.currentPage}` + `&_limit=${context.state.pageSize * getPageCount}`;
            if(context.state.currentCategory != "All"){
                url += `&category=${context.state.currentCategory}`;
            }
            // 添加搜索词判断
            if(context.state.searchTerm != ""){
                url += `&q=${context.state.searchTerm}`;
            }
            let response = await Axios.get(url);
            context.commit("setPageCount", response.headers["x-total-count"]);
            context.commit("addPage", {number: context.state.currentPage, data: response.data, pageCount: getPageCount});
        },
        setCurrentPage(context, page){
            context.commit("_setCurrentPage", page);
            if(!context.state.pages[page]){
                context.dispatch("getPage");
            }
        },
        setPageSize(context, size){
            context.commit("clearPages");
            context.commit("_setPageSize", size);
            context.dispatch("getPage", 2);
        },
        setCurrentCategory(context, category){
            context.commit("clearPages");
            context.commit("_setCurrentCategory", category);
            context.dispatch("getPage", 2);
        },
        search(context, term){
            context.commit("setSearchTerm", term);
            context.commit("clearPages");
            context.dispatch("getPage", 2);
        },
        clearSearchTerm(context){
            context.commit("setSearchTerm", "");
            context.commit("clearPages");
            context.dispatch("getPage", 2);
        }
    }
})

```

在src/components文件夹的Search.vue文件中添加如下内容：
```html
<template>
<div v-if="showSearch" class="row my-2">
    <label class="col-2 col-form-label text-right">Search:</label>
    <input class="col form-control" v-bind:value="searchTerm" v-on:input="doSearch" placeholder="Enter search term..." />
    <button class="col-1 btn btn-sm btn-secondary mx-4" v-on:click="handleClose">Close</button>
</div>
</template>

<script>
import {
    mapMutations,
    mapState,
    mapActions
} from "vuex";

export default {
    computed: {
        ...mapState(["showSearch", "searchTerm"])
    },
    methods: {
        ...mapMutations(["setShowSearch"]),
        ...mapActions(["clearSearchTerm", "search"]),
        handleClose() {
            this.clearSearchTerm();
            this.setShowSearch(false);
        },
        doSearch($event) {
            this.search($event.target.value);
        }
    }
}
</script>

```

在src/components文件夹的Store.vue文件中添加搜索组件：
```html
<template>
<div class="container-fluid">
    <div class="row">
        <div class="col bg-dark text-white">
            <a class="navbar-brand">SPORTS STORE</a>
            <cart-summary />
        </div>
    </div>
    <div class="row">
        <div class="col-3 bg-info p-2">
            <!-- 使用分类组件 -->
            <CategoryControls class="mb-5" />
            <button class="btn btn-block btn-warning mt-5" v-on:click="setShowSearch(true)">Search</button>
        </div>
        <div class="col-9 p-2">
            <!-- 使用搜索组件-->
            <Search />
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
import CartSummary from "./CartSummary";
import {
    mapMutations
} from "vuex";
import Search from "./Search";

export default {
    components: {
        ProductList,
        CategoryControls,
        CartSummary,
        Search
    },
    methods: {
        ...mapMutations(["setShowSearch"])
    }
}
</script>

```

## 管理功能

### 实现认证
使用json web token(jwt)实现登录认证功能

#### 扩展数据商店
在src/store文件夹中添加auth.js文件，其内容如下：
```javascript
import Axios from "axios";

const loginUrl = "http://localhost:3500/login";

export default {
    state: {
        authenticated: false,
        jwt: null
    },
    getters: {
        authenticatedAxios(state){
            return Axios.create({
                headers:{
                    "Authorization":`Bearer<${state.jwt}>`
                }
            });
        }
    },
    mutations:{
        setAuthenticated(state, header){
            state.jwt = header;
            state.authenticated = true;
        },
        clearAuthentication(state){
            state.authenticated = false;
            state.jwt = null;
        }
    },
    actions: {
        async authenticate(context, credentials){
            let response = await Axios.post(loginUrl, credentials);
            if(response.data.success == true){
                context.commit("setAuthenticated", response.data.token);
            }
        }
    }
}

```

在src/store文件夹的index.js文件中添加如下内容：
```javascript
import Vue from "vue";
import Vuex from "vuex";

import Axios from "axios";
import CartModule from "./cart";
import OrdersModule from "./orders";
import AuthModule from "./auth";

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
    modules: {cart: CartModule, orders: OrdersModule, auth: AuthModule }, // 添加认证模块
    state: {
        // products: testData,
        categoriesData: [],
        // productsTotal: testData.length,
        currentPage: 1,
        pageSize: 4,
        currentCategory: "All",
        pages: [],
        serverPageCount: 0,
        searchTerm: "",
        showSearch: false
    },
    getters: {
        // productsFilteredByCategory: state => state.products.filter(p => state.currentCategory == "All" || p.category == state.currentCategory),
        // 根据当前分页以及每页个数返回当前页面产品列表
        processedProducts: (state) => {
            return state.pages[state.currentPage];
        },
        // 计算分页总数
        pageCount: (state) => state.serverPageCount,
        categories: state => ["All", ...state.categoriesData]
    },
    mutations: {
        // 设置当前分页
        _setCurrentPage(state, page){
            state.currentPage = page;
        },
        // 设置每页个数
        _setPageSize(state, size){
            state.pageSize = size;
            state.currentPage = 1;
        },
        // 设置当前分类
        _setCurrentCategory(state, category){
            state.currentCategory = category;
            state.currentPage = 1;
        },
        // setData(state, data){
        //     state.products = data.pdata;
        //     state.productsTotal = data.pdata.length;
        //     state.categoriesData = data.cdata.sort();
        // },
        addPage(state, page){
            for(let i=0; i<page.pageCount; i++){
                Vue.set(state.pages, page.number +i, page.data.slice(i*state.pageSize, (i*state.pageSize) + state.pageSize));
            }
        },
        clearPages(state){
            state.pages.splice(0, state.pages.length);
        },
        setCategories(state, categories){
            state.categoriesData = categories;
        },
        setPageCount(state, count){
            state.serverPageCount = Math.ceil(Number(count)/state.pageSize);
        },
        setShowSearch(state, show){
            state.showSearch = show;
        },
        setSearchTerm(state, term){
            state.searchTerm = term;
            state.currentPage = 1;
        }
    },
    actions: {
        async getData(context) {
            await context.dispatch("getPage", 2);
            context.commit("setCategories", (await Axios.get(categoriesUrl)).data);
        },
        async getPage(context, getPageCount = 1){
            let url = `${productsUrl}?_page=${context.state.currentPage}` + `&_limit=${context.state.pageSize * getPageCount}`;
            if(context.state.currentCategory != "All"){
                url += `&category=${context.state.currentCategory}`;
            }
            // 添加搜索词判断
            if(context.state.searchTerm != ""){
                url += `&q=${context.state.searchTerm}`;
            }
            let response = await Axios.get(url);
            context.commit("setPageCount", response.headers["x-total-count"]);
            context.commit("addPage", {number: context.state.currentPage, data: response.data, pageCount: getPageCount});
        },
        setCurrentPage(context, page){
            context.commit("_setCurrentPage", page);
            if(!context.state.pages[page]){
                context.dispatch("getPage");
            }
        },
        setPageSize(context, size){
            context.commit("clearPages");
            context.commit("_setPageSize", size);
            context.dispatch("getPage", 2);
        },
        setCurrentCategory(context, category){
            context.commit("clearPages");
            context.commit("_setCurrentCategory", category);
            context.dispatch("getPage", 2);
        },
        search(context, term){
            context.commit("setSearchTerm", term);
            context.commit("clearPages");
            context.dispatch("getPage", 2);
        },
        clearSearchTerm(context){
            context.commit("setSearchTerm", "");
            context.commit("clearPages");
            context.dispatch("getPage", 2);
        }
    }
})

```

#### 添加管理组件

在src/components/admin文件夹的Admin.vue文件中添加如下内容
```html
<template>
<div class="bg-danger text-white text-center h4 p-2">Admin Features</div>
</template>

```
在src/components/admin文件夹的Authentication.vue文件中添加如下内容

```html
<template>
<div class="m-2">
    <h4 class="bg-primary text-white text-center p-2">
        SportsStore Administration
    </h4>
    <h4 v-if="showFailureMessage" class="bg-danger text-white text-center p-2 my-2">
        Authentication Failed. Please try again.
    </h4>
    <div class="form-group">
        <label>Username</label>
        <input class="form-control" v-model="$v.username.$model">
        <validation-error v-bind:validation="$v.username" />
    </div>
    <div class="form-group">
        <label>Password</label>
        <input type="password" class="form-control" v-model="$v.password.$model">
        <validation-error v-bind:validation="$v.password" />
    </div>
    <div class="text-center">
        <button class="btn btn-primary" v-on:click="handleAuth">Log In</button>
    </div>
</div>
</template>

<script>
import {
    required
} from 'vuelidate/lib/validators';
import {
    mapActions,
    mapState
} from "vuex";
import ValidationError from "../ValidationError";

export default {
    components: {
        ValidationError
    },
    data: function () {
        return {
            username: "admin",
            password: "secret",
            showFailureMessage: false,
        }
    },
    computed: {
        ...mapState({
            authenticated: state => state.auth.authenticated
        })
    },
    validations: {
        username: {
            required
        },
        password: {
            required
        }
    },
    methods: {
        ...mapActions(["authenticate"]),
        async handleAuth() {
            this.$v.$touch();
            if (!this.$v.$invalid) {
                await this.authenticate({
                    name: this.username,
                    password: this.password
                });
                if (this.authenticated) {
                    this.$router.push("/admin");
                } else {
                    this.showFailureMessage = true;
                }
            }
        }
    }
}
</script>

```

在src/router文件夹的index.js文件中添加如下内容：
```javascript
import Vue from "vue";
import VueRouter from "vue-router";

import Store from "../components/Store";
import ShoppingCart from "../components/ShoppingCart";
import Checkout from "../components/Checkout";
import OrderThanks from "../components/OrderThanks";
import Authentication from "../components/admin/Authentication";
import Admin from "../components/admin/Admin";

Vue.use(VueRouter);

export default new VueRouter({
    mode: "history",
    routes: [
        {path:"/", component: Store},
        {path: "/cart", component: ShoppingCart},
        {path: "/checkout", component: Checkout},
        {path: "/thanks/:id", component: OrderThanks},
        {path: "/login", component: Authentication },
        {path: "/admin", component: Admin},
        {path: "*", redirect: "/"}
    ]
})


```
现在可以访问/login路径查看登录情况

#### 添加路由引导
在src/router文件夹的index.js文件中添加路由引导
```javascript
import Vue from "vue";
import VueRouter from "vue-router";

import Store from "../components/Store";
import ShoppingCart from "../components/ShoppingCart";
import Checkout from "../components/Checkout";
import OrderThanks from "../components/OrderThanks";
import Authentication from "../components/admin/Authentication";
import Admin from "../components/admin/Admin";

import dataStore from "../store";

Vue.use(VueRouter);

export default new VueRouter({
    mode: "history",
    routes: [
        {path:"/", component: Store},
        {path: "/cart", component: ShoppingCart},
        {path: "/checkout", component: Checkout},
        {path: "/thanks/:id", component: OrderThanks},
        {path: "/login", component: Authentication },
        {path: "/admin", component: Admin, 
        beforeEnter(to,from,next){
            if(dataStore.state.auth.authenticated){
                next();
            }else{
                next("/login");
            }
        }},
        {path: "*", redirect: "/"}
    ]
})


```

可以看到，访问/admin路径后，如果管理者未认证，则导航到/login路径下

### 添加管理组件结构
在src/components/admin文件夹的ProductAdmin.vue文件中添加如下内容：
```html
<template>
<div class="bg-danger text-white text-center h4 p-2">
    Product Admin
</div>
</template>

```

接下来在src/components/admin文件夹下的OrderAdmin.vue文件中添加如下内容：
```html
<template>
<div class="bg-danger text-white text-center h4 p-2">
    Order Admin
</div>
</template>

```

接下来修改src/components/admin文件夹中的Admin.vue文件：
```html
<template>
<div class="container-fluid">
    <div class="row">
        <div class="col bg-secondary text-white">
            <a class="navbar-brand">SPORTS STORE Admin</a>
        </div>
    </div>
    <div class="row">
        <div class="col-3 bg-secondary p-2">
            <router-link to="/admin/products" class="btn btn-block btn-primary" active-class="active">
                Products
            </router-link>
            <router-link to="/admin/orders" class="btn btn-block btn-primary" active-class="active">Orders</router-link>
        </div>
        <div class="col-9 p-2">
            <router-view />
        </div>
    </div>
</div>
</template>

```

在src/router文件夹的index.js文件中添加路由
```javascript
import Vue from "vue";
import VueRouter from "vue-router";

import Store from "../components/Store";
import ShoppingCart from "../components/ShoppingCart";
import Checkout from "../components/Checkout";
import OrderThanks from "../components/OrderThanks";
import Authentication from "../components/admin/Authentication";
import Admin from "../components/admin/Admin";
import ProductAdmin from "../components/admin/ProductAdmin";
import OrderAdmin from "../components/admin/OrderAdmin";

import dataStore from "../store";

Vue.use(VueRouter);

export default new VueRouter({
    mode: "history",
    routes: [
        {path:"/", component: Store},
        {path: "/cart", component: ShoppingCart},
        {path: "/checkout", component: Checkout},
        {path: "/thanks/:id", component: OrderThanks},
        {path: "/login", component: Authentication },
        {path: "/admin", component: Admin, 
        beforeEnter(to,from,next){
            if(dataStore.state.auth.authenticated){
                next();
            }else{
                next("/login");
            }
        }, children: [
            {path: "products", component: ProductAdmin},
            {path: "orders", component: OrderAdmin},
            {path: "", redirect: "/admin/products"}
        ]},
        {path: "*", redirect: "/"}
    ]
})


```

### 实现订单管理功能

在src/store文件夹的orders.js文件中添加如下内容：
```javascript
import Axios from "axios";
import Vue from "vue";

const ORDERS_URL = "http://localhost:3500/orders"

export default {
    state: {
        orders: []
    },
    mutations: {
        setOrders(state, data){
            state.orders = data;
        },
        changeOrderShipped(state, order){
            Vue.set(order, "shipped", order.shipped == null || !order.shipped ? true : false);
        }
    },
    actions: {
        async storeOrder(context, order){
            order.cartLines = context.rootState.cart.lines;
            return (await Axios.post(ORDERS_URL, order)).data.id;
        },
        async getOrders(context){
            context.commit("setOrders", (await context.rootGetters.authenticatedAxios.get(ORDERS_URL)).data);
        },
        async updateOrder(context, order){
            context.commit("changeOrderShipped", order);
            await context.rootGetters.authenticatedAxios.put(`${ORDERS_URL}/${order.id}`, order);
        }
    }
}

```

在src/components/admin文件夹的OrderAdmin.vue文件中添加管理订单功能
```html
<template>
<div>
    <h4 class="bg-info text-white text-center p-2">Orders</h4>
    <div class="form-group text-center">
        <input class="form-check-input" type="checkbox" v-model="showShipped" />
        <label class="form-check-label">Show Shipped Orders</label>
    </div>
    <table class="table table-sm table-bordered">
        <thead>
            <tr>
                <th>ID</th>
                <th>Name</th>
                <th>City,Zip</th>
                <th class="text-right">Total</th>
                <th></th>
            </tr>
        </thead>
        <tbody>
            <tr v-if="displayOrders.length == 0">
                <td colspan="5">There are no orders</td>
            </tr>
            <tr v-for="o in displayOrders" v-bind:key="o.id">
                <td>{{o.id}}</td>
                <td>{{o.name}}</td>
                <td>{{`${o.city}, ${o.zip}`}}</td>
                <td class="text-right">{{ getTotal(o) | currency }}</td>
                <td class="text-center">
                    <button class="btn btn-sm btn-danger" v-on:click="shipOrder(o)">{{ o.shipped ? 'Not Shipped' : 'Shipped'}}</button>
                </td>
            </tr>
        </tbody>
    </table>
</div>
</template>

<script>
import {
    mapState,
    mapActions,
    mapMutations
} from "vuex";

export default {
    data: function () {
        return {
            showShipped: false
        }
    },
    computed: {
        ...mapState({
            orders: state => state.orders.orders
        }),
        displayOrders() {
            return this.showShipped ? this.orders : this.orders.filter(o => o.shipped != true);
        }
    },
    methods: {
        ...mapMutations(["changeOrderShipped"]),
        ...mapActions(["getOrders", "updateOrder"]),
        getTotal(order) {
            if (order.cartLines != null && order.cartLines.length > 0) {
                return order.cartLines.reduce((total, line) => total + (line.quantity * line.product.price), 0)
            } else {
                return 0;
            }
        },
        shipOrder(order) {
            this.updateOrder(order);
        }
    },
    created() {
        this.getOrders();
    }
}
</script>

```

现在可以直接登录查看http://localhost:8080/admin/orders，里面记录着客户订单信息




