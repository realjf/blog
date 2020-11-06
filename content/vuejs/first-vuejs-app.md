---
title: "vue.js 2 系列之一 第一个vue.js应用 First Vuejs App"
date: 2020-11-06T10:37:34+08:00
keywords: ["vuejs", "vue.js"]
categories: ["vuejs"]
tags: ["vuejs", "vue.js"]
series: ["pro vue.js2"]
draft: false
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

## 准备开发环境
- 安装最新版node.js
- 使用npm安装@vue/cli命令行工具包
- 安装git
- 安装开发ide，如vscode，sublime text, atom,vim等
- 安装浏览器，chrome,firefox等


> 安装vue命令：npm install -g @vue/cli

## 创建工程项目
```shell script
vue create todo --default
```
### 项目结构解析
执行tree -L 1后得到如下结构
```shell script
├── babel.config.js
├── node_modules
├── package.json
├── package-lock.json
├── public
|      ├── favicon.ico
|      └── index.html
├── README.md
└── src
     ├── App.vue
     ├── assets
     │   └── logo.png
     ├── components
     │   └── HelloWorld.vue
     └── main.js
```
- public/index.html 这是浏览器加载的第一个文件
- src/main.js 这个vue.js应用的配置js文件
- src/App.vue 这是vue.js组件，包含html文档结构和js代码以及css文档样式
- src/assets/logo.png assets文件夹是存放静态资源文件

### 运行开发工具
```shell script
cd todo
npm run serve

# 运行结果如下：
App running at:
  - Local:   http://localhost:8080/
  - Network: http://192.168.51.54:8080/

  Note that the development build is not optimized.
  To create a production build, run npm run build.
```
打开浏览器，在浏览器中输入地址http://localhost:8080/，即可访问vue.js应用

## 替换缺省文档
```html
<template>
<div id="app">
<img src="./assets/logo.png">
<HelloWorld msg="Welcome to Your Vue.js App" />
</div>
</template>
<script>
    import HelloWorld from "./components/HelloWorld.vue"
    export default {
    name: 'app',
    components: {
    HelloWorld
}
}

</script>
<style>
#app {
font-family: 'Avenir', Helvetica, Arial, sans-serif;
-webkit-font-smoothing: antialiased;
-moz-osx-font-smoothing: grayscale;
text-align: center;
color: #2c3e50;
margin-top: 60px;
}
</style>
```
将以上App.vue文件内容替换为如下内容：
```html
<template>
<div id="app">
<h4>
To Do List
</h4>
</div>
</template>
<script>
export default {
name: 'app'
}
</script>
```
### 添加css框架
因为要安装的bootstrap依赖于jquery，所以需要先安装jquery，可以使用如下命令查看
```shell script
npm jquery -v
# 安装jquery
npm install jquery
```
然后在src/main.js下引入jquery

> npm install -g是全局安装，npm install 是在当前目录下的node_modules目录下安装
```javascript
import $ from 'jquery'
```
同时因为bootstrap依赖于popper.js，所以需要安装popper.js
```shell script
npm install popper
```


运行如下命令，安装bootstrap4.0.0到项目
```shell script
npm install bootstrap@4.0.0
```
添加bootstrap到src/main.js文件中
```javascript
import Vue from 'vue'
import App from './App.vue'

Vue.config.productionTip = false

// 添加bootstrap框架
import "bootstrap/dist/css/bootstrap.min.css"

new Vue({
  render: h => h(App),
}).$mount('#app')

```

> css框架非常多，包括bootstrap，这些框架依赖如jquery等js，对html文档进行样式修改，
> 如果想使用vue.js特定的框架，vuetify是个不错的选择，当然还有另外一个如：bootstrap-vue等

#### npm run serve报错处理
##### Module Error (from ./node_modules/eslint-loader/index.js) error  '$' is defined but never used  no-unused-vars
这是因为安装eslint规范
```shell script
npm install eslint

# 进入node_modules目录的.bin目录下，初始化eslint
cd node_modules/.bin/
eslint --init
# 设置选项，除选择vue.js外，其他都选择默认选项

# 最后，将node_modules目录.bin目录下的.eslintrc.js文件拷贝到项目根目录下
# window下
copy .eslintrc.js ..\..\

# linux下
cp .eslintrc.js ../../

# 启动服务即可
cd ../../
npm run serve
```
- 解决方法1：在.eslintrc.js文件中添加如下代码：
```js
"rules": {
	"generator-star-spacing": "off",
	"no-tabs":"off",
	"no-unused-vars":"off",
	"no-console":"off",
	"no-irregular-whitespace":"off",
	"no-debugger": "off"
},
```
- 解决方法2：注释掉不使用的那行代码
- 解决方法3：关闭eslint


### 对html元素添加样式
修改src/App.vue文件
```html
<template>
<div id="app">
<!-- 这里添加样式 -->
<h4 class="bg-primary text-white text-center p-2">
To Do List
</h4>
</div>
</template>
<script>
export default {
name: 'app'
}
</script>
```
重启项目
```shell script
npm run serve
```

## 添加动态内容
在App.vue文件中添加展示数据
```html
<template>
<div id="app">
    <h4 class="bg-primary text-white text-center p-2">
        {{ name }}'s To Do List
    </h4>
</div>
</template>

<script>
export default {
    name: "app",
    data() {
        return {
            name: "realjf"
        }
    },
};
</script>
```
### 展示list任务列表
利用v-for指令对任务列表数据进行循环输出展示
```html
<template>
<div id="app">
    <h4 class="bg-primary text-white text-center p-2">
        {{ name }}'s To Do List
    </h4>
    <div class="container-fluid p-4">
        <div class="row">
            <div class="col font-weight-bold">Task</div>
            <div class="col-2 font-weight-bold">Done</div>
        </div>
        <div class="row" v-for="t in tasks" v-bind:key="t.action">
            <div class="col">{{t.action}}</div>
            <div class="col-2">{{t.done}}</div>
        </div>
    </div>
</div>
</template>

<script>
export default {
    name: "app",
    data() {
        return {
            name: "realjf",
            tasks: [{
                    action: "Buy Flowers",
                    done: false
                },
                {
                    action: "Get Shoes",
                    done: false
                },
                {
                    action: "Collect Tickets",
                    done: true
                },
                {
                    action: "Call Joe",
                    done: false
                }
            ]
        }
    },
};
</script>

```
v-bind:key指令为当前的元素绑定一个id

### 添加checkbox
```html
<template>
<div id="app">
    <h4 class="bg-primary text-white text-center p-2">
        {{ name }}'s To Do List
    </h4>
    <div class="container-fluid p-4">
        <div class="row">
            <div class="col font-weight-bold">Task</div>
            <div class="col-2 font-weight-bold">Done</div>
        </div>
        <div class="row" v-for="t in tasks" v-bind:key="t.action">
            <div class="col">{{ t.action }}</div>
            <div class="col-2">
                <!-- 这里添加checkbox -->
                <input type="checkbox" v-model="t.done" class="form-check-input" />
                {{ t.done }}
            </div>
        </div>
    </div>
</div>
</template>

<script>
export default {
    name: "app",
    data() {
        return {
            name: "realjf",
            tasks: [{
                    action: "Buy Flowers",
                    done: false,
                },
                {
                    action: "Get Shoes",
                    done: false,
                },
                {
                    action: "Collect Tickets",
                    done: true,
                },
                {
                    action: "Call Joe",
                    done: false,
                },
            ],
        };
    },
};
</script>

```
v-model指令是用于绑定数据，当数据有变动时，会自动更新相应位置的变量值，当然，这个是双向数据同步，
当对应元素的值改变时，也会更新绑定变量的值

### 过滤已完成的任务
```html
<template>
<div id="app">
    <h4 class="bg-primary text-white text-center p-2">
        {{ name }}'s To Do List
    </h4>
    <div class="container-fluid p-4">
        <div class="row">
            <div class="col font-weight-bold">Task</div>
            <div class="col-2 font-weight-bold">Done</div>
        </div>
        <div class="row" v-for="t in filteredTasks" v-bind:key="t.action">
            <div class="col">{{ t.action }}</div>
            <div class="col-2 text-center">
                <input type="checkbox" v-model="t.done" class="form-check-input" />
                {{ t.done }}
            </div>
        </div>
        <div class="row bg-secondary py-2 mt-2 text-white">
            <div class="col text-center">
                <input type="checkbox" v-model="hideCompleted" class="form-check-input" />
                <label class="form-check-label font-weight-bold">
                    Hide completed tasks
                </label>
            </div>
        </div>
    </div>
</div>
</template>

<script>
export default {
    name: "app",
    data() {
        return {
            name: "realjf",
            tasks: [{
                    action: "Buy Flowers",
                    done: false,
                },
                {
                    action: "Get Shoes",
                    done: false,
                },
                {
                    action: "Collect Tickets",
                    done: true,
                },
                {
                    action: "Call Joe",
                    done: false,
                },
            ],
            hideCompleted: true
        }
    },
    computed: {
        filteredTasks() {
            return this.hideCompleted ? this.tasks.filter(t => !t.done) : this.tasks
        }
    }
};
</script>

```
- computed 是定义计算属性，可以在数据变动时重新计算属性值并返回结果

### 创建新任务
```html
<template>
<div id="app">
    <h4 class="bg-primary text-white text-center p-2">
        {{ name }}'s To Do List
    </h4>
    <div class="container-fluid p-4">
        <div class="row">
            <div class="col font-weight-bold">Task</div>
            <div class="col-2 font-weight-bold">Done</div>
        </div>
        <div class="row" v-for="t in filteredTasks" v-bind:key="t.action">
            <div class="col">{{ t.action }}</div>
            <div class="col-2 text-center">
                <input type="checkbox" v-model="t.done" class="form-check-input" />
                {{ t.done }}
            </div>
        </div>
        <div class="row py-2">
            <div class="col">
                <input v-model="newItemText" class="form-control" />
            </div>
            <div class="col-2">
                <button class="btn btn-primary" v-on:click="addNewTodo">Add</button>
            </div>
        </div>
        <div class="row bg-secondary py-2 mt-2 text-white">
            <div class="col text-center">
                <input type="checkbox" v-model="hideCompleted" class="form-check-input" />
                <label class="form-check-label font-weight-bold">
                    Hide completed tasks
                </label>
            </div>
        </div>
    </div>
</div>
</template>

<script>
export default {
    name: "app",
    data() {
        return {
            name: "realjf",
            tasks: [{
                    action: "Buy Flowers",
                    done: false,
                },
                {
                    action: "Get Shoes",
                    done: false,
                },
                {
                    action: "Collect Tickets",
                    done: true,
                },
                {
                    action: "Call Joe",
                    done: false,
                },
            ],
            hideCompleted: true,
            newItemText: ""
        }
    },
    computed: {
        filteredTasks() {
            return this.hideCompleted ? this.tasks.filter(t => !t.done) : this.tasks
        }
    },
    methods: {
        addNewTodo() {
            this.tasks.push({
                action: this.newItemText,
                done: false
            });
            this.newItemText = "";
        }
    }
};
</script>

```
- v-on:click 指令用于绑定点击事件
- methods 用于定义js函数，可用于v-on指令绑定用

### 持久存储数据
在App.vue中使用localStorage
```js
<script>
export default {
    name: "app",
    data() {
        return {
            name: "realjf",
            tasks: [],
            hideCompleted: true,
            newItemText: ""
        }
    },
    computed: {
        filteredTasks() {
            return this.hideCompleted ? this.tasks.filter(t => !t.done) : this.tasks
        }
    },
    methods: {
        addNewTodo() {
            this.tasks.push({
                action: this.newItemText,
                done: false
            });
            // 使用localStorage持久存储数据
            localStorage.setItem("todos", JSON.stringify(this.tasks));
            this.newItemText = "";
        },
    },
    created() {
        // 从localStorage中获取数据
        let data = localStorage.getItem("todos");
        if (data != null) {
            this.tasks = JSON.parse(data);
        }
    },
};
</script>
```
- created() 是vue应用生命周期的一个事件，在vue应用创建成功后触发，并执行其中的代码

当你添加新任务后，刷新浏览器将会重载之前保存的数据

### 添加点睛之笔
- 添加删除任务功能
- 在没有可做任务时展示一个信息

```html
<template>
<div id="app">
    <h4 class="bg-primary text-white text-center p-2">
        {{ name }}'s To Do List
    </h4>
    <div class="container-fluid p-4">
        <!-- 展示信息 -->
        <div class="row" v-if="filteredTasks.length == 0">
            <div class="col text-center">
                <b>Nothing to do. Hurrah!</b>
            </div>
        </div>
        <template v-else>
            <div class="row">
                <div class="col font-weight-bold">Task</div>
                <div class="col-2 font-weight-bold">Done</div>
            </div>
            <div class="row" v-for="t in filteredTasks" v-bind:key="t.action">
                <div class="col">{{ t.action }}</div>
                <div class="col-2 text-center">
                    <input type="checkbox" v-model="t.done" class="form-check-input" />
                    {{ t.done }}
                </div>
            </div>
        </template>
        <div class="row py-2">
            <div class="col">
                <input v-model="newItemText" class="form-control" />
            </div>
            <div class="col-2">
                <button class="btn btn-primary" v-on:click="addNewTodo">Add</button>
            </div>
        </div>
        <div class="row bg-secondary py-2 mt-2 text-white">
            <div class="col text-center">
                <input type="checkbox" v-model="hideCompleted" class="form-check-input" />
                <label class="form-check-label font-weight-bold">
                    Hide completed tasks
                </label>
            </div>
            <div class="col text-center">
                <button class="btn btn-sm btn-warning" v-on:click="deleteCompleted">Delete Completed</button>
            </div>
        </div>
    </div>
</div>
</template>

<script>
export default {
    name: "app",
    data() {
        return {
            name: "realjf",
            tasks: [],
            hideCompleted: true,
            newItemText: ""
        }
    },
    computed: {
        filteredTasks() {
            return this.hideCompleted ? this.tasks.filter(t => !t.done) : this.tasks
        }
    },
    methods: {
        addNewTodo() {
            this.tasks.push({
                action: this.newItemText,
                done: false
            });
            // 使用localStorage持久存储数据
            this.storeData();

            this.newItemText = "";
        },
        storeData() {
            localStorage.setItem("todos", JSON.stringify(this.tasks));
        },
        // 添加删除功能
        deleteCompleted() {
            this.tasks = this.tasks.filter(t => !t.done);
            this.storeData();
        }
    },
    created() {
        // 从localStorage中获取数据
        let data = localStorage.getItem("todos");
        if (data != null) {
            this.tasks = JSON.parse(data);
        }
    },
};
</script>

```
- v-if指令 是if的判断语句，后接判断条件，当然其结构还包括v-else，v-else-if等
- template 模板标签，可以用于定义模板结构






