---
title: "vue.js 2 系列之八 运动商店A Real App 4"
date: 2020-11-09T14:15:41+08:00
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
[/vuejs/a-real-app-3/](/vuejs/a-real-app-3/)

首先，运行json web服务
```shell script
npm run json
```

然后运行运动商店http服务器
```shell script
npm run serve
```

## 添加商品管理功能
在src/store文件夹中的index.js文件中添加如下内容
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
    modules: {cart: CartModule, orders: OrdersModule, auth: AuthModule }, // 添加购物车模块
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
        categories: state => ["All", ...state.categoriesData],
        productById:(state) => (id) => {
            return state.pages[state.currentPage].find(p => p.id == id);
        }
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
        },
        // 添加商品
        _addProduct(state, product){
            state.pages[state.currentPage].unshift(product);
        },
        _updateProduct(state, product){
            let page = state.pages[state.currentPage];
            let index = page.findIndex(p => p.id == product.id);
            Vue.set(page, index, product);
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
        },
        // 添加商品
        async addProduct(context, product){
            let data = (await context.getters.authenticatedAxios.post(productsUrl, product)).data;
            product.id = data.id;
            this.commit("_addProduct", product);
        },
        async removeProduct(context, product){
            await context.getters.authenticatedAxios.delete(`${productsUrl}/${product.id}`);
            context.commit("clearPages");
            context.dispatch("getPage", 1);
        },
        async updateProduct(context, product){
            await context.getters.authenticatedAxios.put(`${productsUrl}/${product.id}`, product);
            this.commit("_updateProduct", product);
        }
    }
})

```
### 显示商品列表
在src/components/admin文件夹的ProductAdmin.vue文件中添加如下内容

```html

<template>
<div>
    <router-link to="/admin/products/create" class="btn btn-primary my-2">
        Create Product
    </router-link>
    <table class="table table-sm table-bordered">
        <thead>
            <tr>
                <th>ID</th>
                <th>Name</th>
                <th>Category</th>
                <th class="text-right">Price</th>
                <th></th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="p in products" v-bind:key="p.id">
                <td>{{p.id}}</td>
                <td>{{p.name}}</td>
                <td>{{p.category}}</td>
                <td class="text-right">{{p.price|currency}}</td>
                <td class="text-center">
                    <button class="btn btn-sm btn-danger mx-1" v-on:click="removeProduct(p)">Delete</button>
                    <button class="btn btn-sm btn-warning mx-1" v-on:click="handleEdit(p)">Edit</button>
                </td>
            </tr>
        </tbody>
    </table>
    <page-controls />
</div>
</template>

<script>
import PageControls from "../PageControls";
import {
    mapGetters,
    mapActions
} from "vuex";

export default {
    components: {
        PageControls
    },
    computed: {
        ...mapGetters({
            products: "processedProducts"
        })
    },
    methods: {
        ...mapActions({
            removeProduct: "removeProduct"
        }),
        handleEdit(product) {
            this.$router.push(`/admin/products/edit/${product.id}`);
        }
    }
}
</script>

```

### 添加编辑和路由
在src/components/admin文件夹的ProductEditor.vue文件中添加如下内容
```html
<template>
<div class="bg-info text-white text-center h4 p-2">Product Editor</div>
</template>

```
在src/router的index.js中添加路由信息
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
import ProductEditor from "../components/admin/ProductEditor";

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
            {path: "products/:op(create|edit)/:id(\\d+)?", component: ProductEditor},
            {path: "products", component: ProductAdmin},
            {path: "orders", component: OrderAdmin},
            {path: "", redirect: "/admin/products"}
        ]},
        {path: "*", redirect: "/"}
    ]
})


```

### 实现编辑器功能
在src/components/admin文件夹的ProductEditor.vue文件中添加如下内容：
```html
<template>
<div>
    <h4 class="text-center text-white p-2" v-bind:class="themeClass">
        {{ editMode ?"Edit" : "Create Product"}}
    </h4>
    <h4 v-if="$v.$invalid && $v.dirty" class="bg-danger text-white text-center p-2">Values Required for All Fields</h4>
    <div class="form-group" v-if="editMode">
        <label>ID (Not Editable)</label>
        <input class="form-control" disabled v-model="product.id" />
    </div>
    <div class="form-group">
        <label>Name</label>
        <input class="form-control" v-model="product.name" />
    </div>
    <div class="form-group">
        <label>Description</label>
        <input class="form-control" v-model="product.description" />
    </div>
    <div class="form-group">
        <label>Category</label>
        <select v-model="product.category" class="form-control">
            <option v-for="c in categories" v-bind:key="c">{{c}}</option>
        </select>
    </div>
    <div class="form-group">
        <label>Price</label>
        <input class="form-control" v-model="product.price" />
    </div>
    <div class="text-center">
        <router-link to="/admin/products" class="btn btn-secondary m-1">Cancel</router-link>
        <button class="btn m-1" v-bind:class="themeClassButton" v-on:click="handleSave">{{editMode ? "Save Changes" : "Store Product"}}</button>
    </div>
</div>
</template>

<script>
import {
    mapState,
    mapActions
} from "vuex";
import {
    required
} from "vuelidate/lib/validators";

export default {
    data: function () {
        return {
            product: {}
        }
    },
    computed: {
        ...mapState({
            pages: state => state.pages,
            currentPage: state => state.currentPage,
            categories: state => state.categoriesData
        }),
        editMode() {
            return this.$route.params["op"] == "edit";
        },
        themeClass() {
            return this.editMode ? "bg-info" : "bg-primary";
        },
        themeClassButton() {
            return this.editMode ? "btn-info" : "btn-primary";
        }
    },
    validations: {
        product: {
            name: {
                required
            },
            description: {
                required
            },
            category: {
                required
            },
            price: {
                required
            }
        }
    },
    methods: {
        ...mapActions({
            addProduct: "addProduct",
            updateProduct: "updateProduct"
        }),
        async handleSave() {
            this.$v.$touch(); // 触发验证
            console.log(this.$v.$invalid);
            // $invalid -- 验证状态，true-验证不通过，false-验证通过
            if (!this.$v.$invalid) {
                if (this.editMode) {
                    console.log(this.product);
                    await this.updateProduct(this.product);
                } else {
                    await this.addProduct(this.product);
                }
                this.$router.push("/admin/products");
            }
        }
    },
    created() {
        if (this.editMode) {
            Object.assign(this.product, this.$store.getters.productById(this.$route.params["id"]))
        }
    }
}
</script>

```

## 部署商店

### 准备开发应用

#### 准备数据存储

在src/store文件夹的index.js文件中，修改基础url地址
```javascript
import Vue from "vue";
import Vuex from "vuex";

import Axios from "axios";
import CartModule from "./cart";
import OrdersModule from "./orders";
import AuthModule from "./auth";

Vue.use(Vuex);

const baseUrl = "/api";
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
    strict: false, // 修改检查模式
    modules: {cart: CartModule, orders: OrdersModule, auth: AuthModule }, // 添加购物车模块
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
        categories: state => ["All", ...state.categoriesData],
        productById:(state) => (id) => {
            return state.pages[state.currentPage].find(p => p.id == id);
        }
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
        },
        // 添加商品
        _addProduct(state, product){
            state.pages[state.currentPage].unshift(product);
        },
        _updateProduct(state, product){
            let page = state.pages[state.currentPage];
            let index = page.findIndex(p => p.id == product.id);
            Vue.set(page, index, product);
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
        },
        // 添加商品
        async addProduct(context, product){
            let data = (await context.getters.authenticatedAxios.post(productsUrl, product)).data;
            product.id = data.id;
            this.commit("_addProduct", product);
        },
        async removeProduct(context, product){
            await context.getters.authenticatedAxios.delete(`${productsUrl}/${product.id}`);
            context.commit("clearPages");
            context.dispatch("getPage", 1);
        },
        async updateProduct(context, product){
            await context.getters.authenticatedAxios.put(`${productsUrl}/${product.id}`, product);
            this.commit("_updateProduct", product);
        }
    }
})

```
修改 src/store目录下的auth.js文件：

```javascript
import Axios from "axios";

// 修改登录地址
const loginUrl = "/api/login";

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

修改src/store目录下的orders.js文件：
```javascript
import Axios from "axios";
import Vue from "vue";

// 修改地址
const ORDERS_URL = "/api/orders"

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
移除认证组件中的认证信息，src/components/admin目录下的Authentication.vue文件
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
            username: null,
            password: null,
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

#### 随请求加载管理功能
在src/router文件夹的index.js文件中添加如下内容：
```javascript
import Vue from "vue";
import VueRouter from "vue-router";

import Store from "../components/Store";
import ShoppingCart from "../components/ShoppingCart";
import Checkout from "../components/Checkout";
import OrderThanks from "../components/OrderThanks";
// import Authentication from "../components/admin/Authentication";
// import Admin from "../components/admin/Admin";
// import ProductAdmin from "../components/admin/ProductAdmin";
// import OrderAdmin from "../components/admin/OrderAdmin";
// import ProductEditor from "../components/admin/ProductEditor";

const Authentication = () => import(/* webpackChunkName: "admin" */ "../components/admin/Authentication");
const Admin = () => import(/* webpackChunkName: "admin" */ "../components/admin/Admin");
const ProductAdmin = () => import(/* webpackChunkName: "admin" */ "../components/admin/ProductAdmin");
const OrderAdmin = () => import(/* webpackChunkName: "admin" */ "../components/admin/OrderAdmin");
const ProductEditor = () => import(/* webpackChunkName: "admin" */ "../components/admin/ProductEditor");

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
            {path: "products/:op(create|edit)/:id(\\d+)?", component: ProductEditor},
            {path: "products", component: ProductAdmin},
            {path: "orders", component: OrderAdmin},
            {path: "", redirect: "/admin/products"}
        ]},
        {path: "*", redirect: "/"}
    ]
})


```
#### 创建数据文件
在 data.json文件中展示商品内容
```json
{
    "products": [
      {"id": 1, "name": "Kayak", "category": "Watersports", "description": "A boat for one person", "price": 275},
      {"id": 2, "name": "Lifejacket", "category": "Watersports", "description": "Protective and fashionable", "price": 48.95},
      {"id": 3, "name": "Soccer Ball", "category": "Soccer", "description": "FIFA-approved size and weight", "price": 19.50},
      {"id": 4, "name": "Corner Flags", "category": "Soccer", "description": "Give your playing field a professional touch", "price": 34.95},
      {"id": 5, "name": "Stadium", "category": "Soccer", "description": "Flat-packed 35,000-seat stadium", "price": 79500},
      {"id": 6, "name": "Thinking Cap", "category": "Chess", "description": "Improve brain efficiency by 75%", "price": 16},
      {"id": 7, "name": "Unsteady Chair", "category": "Chess", "description": "Secretly give your opponent a disadvantage", "price": 29.95},
      {"id": 8, "name": "Human Chess Board", "category": "Chess", "description": "A fun game for the family", "price": 75},
      {"id": 9, "name": "Bling Bling King", "category": "Chess", "description": "Gold-plated, diamond-studded King", "price": 1200}
    ],
    "categories": ["Watersports", "Soccer", "Chess"],
    "orders": []
  }
```
### 构建应用
```shell script
npm run build
```
### 测试待发布应用
添加一些包
```shell script
npm install --save-dev express@4.16.3
npm install --save-dev connect-history-api-fallback@1.5.0
```

在项目根目录下的server.js文件中添加如下内容
```javascript
const express = require("express");
const history = require("connect-history-api-fallback");
const jsonServer = require("json-server");
const bodyParser = require("body-parser");
const auth = require("./authMiddleware");
const router = jsonServer.router("data.json");

const app = express();
app.use(bodyParser.json());
app.use(auth);
app.use("/api", router);
app.use(history());
app.use("/", express.static("./dist"));

app.listen(80, function(){
    console.log("HTTP Server running on port 80");
});

```

测试发布构建
```shell script
node server.js
```
然后直接在浏览器中访问http://localhost查看效果

### 部署应用
#### 创建package文件
为了部署应用到Docker，需要创建一个package.js的版本文件，
在根目录下添加一个deploy-package.json文件，其内容如下：
```json
{
    "name": "store-vuejs",
    "version": "1.0.0",
    "private": true,

    "dependencies": {
        "faker": "^4.1.0",
        "json-server": "^0.12.1",
        "jsonwebtoken": "^8.1.1",
        "express": "4.16.3",
        "connect-history-api-fallback": "1.5.0"
    }
}
```
#### 创建Docker容器

在项目根目录下的Dockerfile文件中添加如下内容：
```dockerfile
FROM node:8.11.2
RUN mkdir -p /usr/src/store-vuejs

COPY dist /usr/src/store-vuejs/dist

COPY authMiddleware.js /usr/src/store-vuejs/
COPY data.json /usr/src/store-vuejs/
COPY server.js /usr/src/store-vuejs/server.js
COPY deploy-package.json /usr/src/store-vuejs/package.json

WORKDIR /usr/src/store-vuejs

RUN npm install

CMD ["node", "server.js"]
```

构建docker镜像
```shell script
docker build . -t store-vuejs -f Dockerfile
```
#### 运行应用
创建一个docker容器
```shell script
docker run -p 80:80 store-vuejs
```
现在就可以在浏览器中访问http://localhost了

查看当前正在运行的docker
```shell script
docker ps
```


停止docker容器
```shell script
docker stop {CONTAINER_ID}
```


