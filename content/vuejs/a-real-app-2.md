---
title: "vue.js 2 系列之六 运动商店 A Real App 2"
date: 2020-11-07T11:49:25+08:00
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

# 下单
## 基于之前一篇基础之上进行构建
[/vuejs/a-real-app/](/vuejs/a-real-app/)

## 创建购物车预置
在src/components文件夹下新建ShoppingCart.vue文件，其内容如下：
```html
<template>
<h4 class="bg-primary text-white text-center p-2">
    placeholder for Cart
</h4>
</template>

```

## 配置url路由
在src/router文件夹中添加index.js文件中添加如下内容：
```javascript
import Vue from "vue";
import VueRouter from "vue-router";

import Store from "../components/Store";
import ShoppingCart from "../components/ShoppingCart";

Vue.use(VueRouter);

export default new VueRouter({
    mode: "history",
    routes: [
        {path:"/", component: Store},
        {path: "/cart", component: ShoppingCart},
        {path: "*", redirect: "/"}
    ]
})
```

将上面的路由文件添加到main.js中
```javascript
import Vue from 'vue'
import App from './App.vue'

// 引入jquery
import $ from 'jquery'

Vue.config.productionTip = false

// 添加bootstrap框架
import "bootstrap/dist/css/bootstrap.min.css";
import "font-awesome/css/font-awesome.min.css";

import store from "./store";
import router from "./router";

new Vue({
  render: h => h(App),
  store,
  router
}).$mount('#app')

```
### 添加路由组件
在App.vue文件中添加如下内容：
```html
<template>
<router-view />
</template>

<script>
// import Store from './components/Store';
import {
    mapActions
} from "vuex";

export default {
    name: 'App',
    // components: {Store},
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

## 实现购物车功能
### 添加数据存储模块

在src/store文件夹中添加cart.js文件，其内容为：
```javascript
export default {
    namespaced: true,
    state: {
        lines: []
    },
    getters:{
        itemCount: state => state.lines.reduce((total, line) => total + line.quantity, 0),
        totalPrice: state => state.lines.reduce((total, line) => total + (line.quantity * line.product.price), 0),
    },
    mutations:{
        addProduct(state, product){
            let line = state.lines.find(line => line.product.id == product.id);
            if(line != null){
                line.quantity++;
            }else{
                state.lines.push({product: product, quantity: 1});
            }
        },
        changeQuantity(state, update){
            update.line.quantity = update.quantity;
        },
        removeProduct(state, lineToRemove){
            let index = state.lines.findIndex(line => line == lineToRemove);
            if(index > -1){
                state.lines.splice(index, 1);
            }
        }
    }
}
```
在src/store文件夹的index.js中添加购物车模块
```javascript
import Vue from "vue";
import Vuex from "vuex";

import Axios from "axios";
import CartModule from "./cart";

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
    modules: {cart: CartModule }, // 添加购物车模块
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
        async getData(context) {
            let pdata = (await Axios.get(productsUrl)).data;
            let cdata = (await Axios.get(categoriesUrl)).data;
            console.log(pdata, cdata);
            context.commit("setData", {pdata, cdata});
        }
    }
})

```

### 添加商品选择功能

在src/components中的ProductList.vue中添加如下内容：
````html
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
        <div class="card-text bg-white p-1">
            {{p.description}}
            <button class="btn btn-success btn-sm float-right" v-on:click="handleProductAdd(p)">Add To Cart</button>
        </div>
    </div>
    <page-controls />
</div>
</template>

<script>
import {
    mapGetters,
    mapMutations // 导入
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
    // 添加过滤函数，格式化价格
    filters: {
        currency(value) {
            return new Intl.NumberFormat("en-US", {
                style: "currency",
                currency: "USD"
            }).format(value);
        }
    },
    methods: {
        ...mapMutations({
            addProduct: "cart/addProduct"
        }),
        handleProductAdd(product) {
            this.addProduct(product);
            this.$router.push("/cart");
        }
    }
}
</script>

````
### 显示购物车内容
在src/components文件夹的ShoppingCartLine.vue文件中添加如下内容：
```html
<template>
<tr>
    <td>
        <input type="number" class="form-control-sm" style="width:5em" v-bind:value="qvalue" v-on:input="sendChangeEvent" />
    </td>
    <td>
        {{ line.product.name}}
    </td>
    <td class="text-right">{{line.product.price | currency}}</td>
    <td class="text-right">
        {{(line.quantity * line.product.price) | currency }}
    </td>
    <td class="text-center">
        <button class="btn btn-sm btn-danger" v-on:click="sendRemoveEvent">Remove</button>
    </td>
</tr>
</template>

<script>
export default {
    props: ["line"],
    data: function () {
        return {
            qvalue: this.line.quantity
        }
    },
    methods: {
        sendChangeEvent($event) {
            if ($event.target.value > 0) {
                this.$emit("quantity", Number($event.target.value));
                this.qvalue = $event.target.value;
            } else {
                this.$emit("quantity", 1);
                this.qvalue = 1;
                $event.target.value = this.qvalue;
            }
        },
        sendRemoveEvent() {
            this.$emit("remove", this.line);
        }
    }
}
</script>

```
- props：声明父级组件中的变量到当前组件中，是单向数据流，所有的prop都使得其父级prop的更新会向下流动到子组件中，反之则不行，所以子组件也不应该改变其内部的prop的值
- this.$emit 表示发送通知事件


现在可以在src/components文件夹的ShoppingCart.vue文件中添加购物内容：
```html
<template>
<div class="container-fluid">
    <div class="row">
        <div class="col bg-dark text-white">
            <a class="navbar-brand">SPORTS STORE</a>
        </div>
    </div>
    <div class="row">
        <div class="col mt-2">
            <h2 class="text-center">Your Cart</h2>
            <table class="table table-bordered table-triped p-2">
                <thead>
                    <tr>
                        <th>Quantity</th>
                        <th>Product</th>
                        <th class="text-right">Price</th>
                        <th class="text-right">Subtotal</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-if="lines.length == 0">
                        <td colspan="4" class="text-center">Your cart is empty</td>
                    </tr>
                    <cart-line v-for="line in lines" v-bind:key="line.product.id" v-bind:line="line" v-on:quantity="handleQuantityChange(line, $event)" v-on:remove="remove" />
                </tbody>
                <tfoot v-if="lines.length > 0">
                    <tr>
                        <td colspan="3" class="text-right">Total:</td>
                        <td class="text-right">{{totalPrice | currency}}</td>
                    </tr>
                </tfoot>
            </table>
        </div>
    </div>
    <div class="row">
        <div class="col">
            <div class="text-center">
                <router-link to="/" class="btn btn-secondary m-1">Continue Shopping</router-link>
                <router-link to="/checkout" class="btn btn-primary m-1" v-bind:disabled="lines.length==0">Checkout</router-link>
            </div>
        </div>
    </div>
</div>
</template>

<script>
import {
    mapState,
    mapMutations,
    mapGetters
} from "vuex";
import CartLine from "./ShoppingCartLine";

export default {
    components: {
        CartLine
    },
    computed: {
        ...mapState({
            lines: state => state.cart.lines
        }),
        ...mapGetters({
            totalPrice: "cart/totalPrice"
        })
    },
    methods: {
        ...mapMutations({
            change: "cart/changeQuantity",
            remove: "cart/removeProduct"
        }),
        handleQuantityChange(line, $event) {
            this.change({
                line,
                quantity: $event
            });
        }
    },
}
</script>

```
- v-bind:line指令，用于设置line prop的值
- v-on指令用于接收自定义事件
- router-link标签，用于生成导航元素
- to：用于绑定路由地址

### 创建全局过滤
在main.js文件中添加如下内容：
```javascript
import Vue from 'vue'
import App from './App.vue'

// 引入jquery
import $ from 'jquery'

Vue.config.productionTip = false

// 添加bootstrap框架
import "bootstrap/dist/css/bootstrap.min.css";
import "font-awesome/css/font-awesome.min.css";

import store from "./store";
import router from "./router";

// 添加全局过滤
Vue.filter("currency", (value) => new Intl.NumberFormat("en-US", {style: "currency", currency: "USD"}).format(value));

new Vue({
  render: h => h(App),
  store,
  router
}).$mount('#app')

```

### 测试购物车基本功能

### 将购物车数据持久化

在src/store文件夹中的cart.js文件中添加如下内容:
```javascript
export default {
    namespaced: true,
    state: {
        lines: []
    },
    getters:{
        itemCount: state => state.lines.reduce((total, line) => total + line.quantity, 0),
        totalPrice: state => state.lines.reduce((total, line) => total + (line.quantity * line.product.price), 0),
    },
    mutations:{
        addProduct(state, product){
            let line = state.lines.find(line => line.product.id == product.id);
            if(line != null){
                line.quantity++;
            }else{
                state.lines.push({product: product, quantity: 1});
            }
        },
        changeQuantity(state, update){
            update.line.quantity = update.quantity;
        },
        removeProduct(state, lineToRemove){
            let index = state.lines.findIndex(line => line == lineToRemove);
            if(index > -1){
                state.lines.splice(index, 1);
            }
        },
        setCartData(state, data) {
            state.lines = data;
        }
    },
    actions: {
        loadCartData(context){
            let data = localStorage.getItem("cart");
            if(data != null){
                context.commit("setCartData", JSON.parse(data));
            }
        },
        storeCartData(context){
            localStorage.setItem("cart", JSON.stringify(context.state.lines));
        },
        clearCartData(context){
            context.commit("setCartData", []);
        },
        initializeCart(context, store){
            context.dispatch("loadCartData");
            store.watch(state => state.cart.lines, () => context.dispatch("storeCartData"), {deep: true});
        }
    }
}
```
- context.dispatch()，当数据改变时，调用storeCartData动作，deep为true表示当state.cart.lines数组任何属性改变时请通知我


接下来在App.vue中添加初始化购物车代码
```html
<template>
<router-view />
</template>

<script>
// import Store from './components/Store';
import {
    mapActions
} from "vuex";

export default {
    name: 'App',
    // components: {Store},
    methods: {
        ...mapActions({
            getData: "getData",
            initializeCart: "cart/initializeCart"
        })
    },
    created() {
        this.getData();
        // 初始化购物车
        this.initializeCart(this.$store);
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
### 添加购物车简要信息窗口

在src/components文件夹的CartSummary.vue文件中添加如下内容：
```html
<template>
<div class="float-right">
    <small>
        Your cart:
        <span v-if="itemCount > 0">{{itemCount}} item(s) {{totalPrice | currency}}</span>
        <span v-else>(empty)</span>
    </small>
    <router-link to="/cart" class="btn btn-sm bg-dark text-white" v-bind:disabled="itemCount==0">
        <i class="fa fa-shopping-cart"></i>
    </router-link>
</div>
</template>

<script>
import {
    mapGetters
} from 'vuex';

export default {
    computed: {
        ...mapGetters({
            itemCount: "cart/itemCount",
            totalPrice: "cart/totalPrice"
        })
    },
}
</script>

```

在src/components文件夹的Store.vue文件中添加购物车简要窗口
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
import CartSummary from "./CartSummary";
export default {
    components: {
        ProductList,
        CategoryControls,
        CartSummary
    }
}
</script>

```

## 添加订单结算功能
在src/store文件夹的orders.js文件中添加如下内容：
```javascript
import Axios from "axios";

const ORDERS_URL = "http://localhost:3500/orders"

export default {
    actions: {
        async storeOrder(context, order){
            order.cartLines = context.rootState.cart.lines;
            return (await Axios.post(ORDERS_URL, order)).data.id;
        }
    }
}

```

在src/store文件夹的index.js中导入模块
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
        async getData(context) {
            let pdata = (await Axios.get(productsUrl)).data;
            let cdata = (await Axios.get(categoriesUrl)).data;
            console.log(pdata, cdata);
            context.commit("setData", {pdata, cdata});
        }
    }
})

```

### 创建和注册结算组件
在src/components文件夹中Checkout.vue中添加如下内容：
```html
<template>
<div>
    <div class="container-fluid">
        <div class="row">
            <div class="col bg-dark text-white">
                <a class="navbar-brand">SPORTS STORE</a>
            </div>
        </div>
    </div>
    <div class="m-2">
        <div class="form-group m-2">
            <label>Name</label>
            <input v-model="name" class="form-control" />
        </div>
    </div>
    <div class="text-center">
        <router-link to="/cart" class="btn btn-secondary m-1">Back</router-link>
        <button class="btn btn-primary m-1" v-on:click="submitOrder">Place Order</button>
    </div>
</div>
</template>

<script>
export default {
    data: function () {
        return {
            name: null
        }
    },
    methods: {
        submitOrder() {
            // todo: save order
        }
    }
}
</script>

```

在src/components文件夹OrderThanks.vue中添加如下内容：
```html
<template>
<div class="m-2 text-center">
    <h2>Thanks!</h2>
    <p>Thanks for placing your order, which is #{{orderId}}.</p>
    <p>We'll ship your goods as soon as possible.</p>
    <router-link to="/" class="btn btn-primary">Return to Store</router-link>
</div>
</template>

<script>
export default {
    computed: {
        orderId() {
            return this.$route.params.id;
        }
    },
}
</script>

```
- this.$route，对于所有组件皆可用，通过路由组件获取路由参数

在src/router文件夹index.js中添加如下内容：
```javascript
import Vue from "vue";
import VueRouter from "vue-router";

import Store from "../components/Store";
import ShoppingCart from "../components/ShoppingCart";
import Checkout from "../components/Checkout";
import OrderThanks from "../components/OrderThanks";

Vue.use(VueRouter);

export default new VueRouter({
    mode: "history",
    routes: [
        {path:"/", component: Store},
        {path: "/cart", component: ShoppingCart},
        {path: "/checkout", component: Checkout},
        {path: "/thanks/:id", component: OrderThanks},
        {path: "*", redirect: "/"}
    ]
})


```

### 添加表单验证
在main.js文件中添加如下内容：
```javascript
import Vue from 'vue'
import App from './App.vue'

// 引入jquery
import $ from 'jquery'

Vue.config.productionTip = false

// 添加bootstrap框架
import "bootstrap/dist/css/bootstrap.min.css";
import "font-awesome/css/font-awesome.min.css";

import store from "./store";
import router from "./router";
import Vuelidate from "vuelidate";

// 添加全局过滤
Vue.filter("currency", (value) => new Intl.NumberFormat("en-US", {style: "currency", currency: "USD"}).format(value));

// 添加验证功能
Vue.use(Vuelidate);

new Vue({
  render: h => h(App),
  store,
  router
}).$mount('#app')

```

在src/components文件夹的ValidationError.vue文件中添加如下内容：
```html

<template>
<div v-if="show" class="text-danger">
    <div v-for="m in messages" v-bind:key="m">{{m}}</div>
</div>
</template>

<script>
export default {
    props: ["validation"],
    computed: {
        show() {
            return this.validation.$dirty && this.validation.$invalid
        },
        messages() {
            let messages = [];
            if (this.validation.$dirty) {
                if (this.hasValidationError("required")) {
                    messages.push("Please enter a value")
                } else if (this.hasValidationError("email")) {
                    messages.push("Please enter a valid email address");
                }
            }
            return messages;
        }
    },
    methods: {
        hasValidationError(type) {
            // 新版本的ESLint使用了禁止直接调用 Object.prototypes 的内置属性开关，说白了就是ESLint 配置文件中的 "extends": "eslint:recommended" 属性启用了此规则，所以使用如下方法调用hasOwnProperty
             return Object.prototype.hasOwnProperty.call(this.validation.$params, type) && !this.validation[type];
        }
    }
}
</script>

```

| 名称 | 说明 |
|:---: |:---:|
|$invalid| 为真，元素内容没有通过其中一条验证规则|
|$dirty| 为真，元素已经被便编辑过|
|required| 如果存在该属性，表示元素必须验证通过，如果为假，表示元素没有值|
|email| 如果存在该属性，邮箱验证规则必须通过，如果为假，表示元素不是一个有效的邮箱地址|


接下来，在src/components文件夹的Checkout.vue文件中添加验证规则
```html
<template>
<div>
    <div class="container-fluid">
        <div class="row">
            <div class="col bg-dark text-white">
                <a class="navbar-brand">SPORTS STORE</a>
            </div>
        </div>
    </div>
    <div class="m-2">
        <div class="form-group m-2">
            <label>Name</label>
            <input v-model="$v.name.$model" class="form-control" />
            <!-- 添加验证规则 -->
            <validation-error v-bind:validation="$v.name" />
        </div>
    </div>
    <div class="text-center">
        <router-link to="/cart" class="btn btn-secondary m-1">Back</router-link>
        <button class="btn btn-primary m-1" v-on:click="submitOrder">Place Order</button>
    </div>
</div>
</template>

<script>
import {
    required
} from "vuelidate/lib/validators";
import ValidationError from "./ValidationError";

export default {
    components: {
        ValidationError
    },
    data: function () {
        return {
            name: null
        }
    },
    validations: {
        name: {
            required
        }
    },
    methods: {
        submitOrder() {
            this.$v.$touch();
            // todo: save order
        }
    }
}
</script>

```
- $v，验证规则功能通过属性$v调用
- $v.name.$model，表示绑定验证规则validations里的name变量规则 
- this.$v.$touch()，触发验证规则


### 添加遗留的信息以及验证处理

在src/components文件夹的Checkout.vue文件中添加如下内容
```html
<template>
<div>
    <div class="container-fluid">
        <div class="row">
            <div class="col bg-dark text-white">
                <a class="navbar-brand">SPORTS STORE</a>
            </div>
        </div>
    </div>
    <div class="m-2">
        <div class="form-group m-2">
            <label>Name</label>
            <input v-model="$v.order.name.$model" class="form-control" />
            <!-- 添加验证规则 -->
            <validation-error v-bind:validation="$v.order.name" />
        </div>
    </div>
    <div class="m-2">
        <div class="form-group m-2">
            <label>Email</label>
            <input v-model="$v.order.email.$model" class="form-control" />
            <validation-error v-bind:validation="$v.order.email" />
        </div>
    </div>
    <div class="m-2">
        <div class="form-group m-2">
            <label>Address</label>
            <input v-model="$v.order.address.$model" class="form-control" />
            <validation-error v-bind:validation="$v.order.address" />
        </div>
    </div>
    <div class="m-2">
        <div class="form-group m-2">
            <label>City</label>
            <input v-model="$v.order.city.$model" class="form-control" />
            <validation-error v-bind:validation="$v.order.city" />
        </div>
    </div>
    <div class="m-2">
        <div class="form-group m-2">
            <label>Zip</label>
            <input v-model="$v.order.zip.$model" class="form-control" />
            <validation-error v-bind:validation="$v.order.zip" />
        </div>
    </div>
    <div class="text-center">
        <router-link to="/cart" class="btn btn-secondary m-1">Back</router-link>
        <button class="btn btn-primary m-1" v-on:click="submitOrder">Place Order</button>
    </div>
</div>
</template>

<script>
import {
    required,
    email
} from "vuelidate/lib/validators";
import ValidationError from "./ValidationError";
import {
    mapActions
} from "vuex";

export default {
    components: {
        ValidationError
    },
    data: function () {
        return {
            order: {
                name: null,
                email: null,
                address: null,
                city: null,
                zip: null
            }
        }
    },
    validations: {
        order: {
            name: {
                required
            },
            email: {
                required,
                email
            },
            address: {
                required
            },
            city: {
                required
            },
            zip: {
                required
            }
        }

    },
    methods: {
        ...mapActions({
            "storeOrder": "storeOrder",
            "clearCart": "cart/clearCartData"
        }),
        async submitOrder() {
            this.$v.$touch();
            if (!this.$v.$invalid) {
                let order = await this.storeOrder(this.order);
                this.clearCart();
                this.$router.push(`/thanks/${order}`);
            }
        }
    }
}
</script>

```










