---
title: "Django后端 + Vue前端 构建Web开发框架"
date: 2019-10-14T15:17:48+08:00
keywords: ["python", "vue", "django", "web", "fullstack"]
categories: ["python", "vue"]
tags: ["python", "vue", "django", "web", "fullstack"]
draft: false
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

## 一、准备
- Django >= 1.11
- python >= 3.6
- mysql >= 5.7
- node >= 10.15
- vue-cli >= 2.0

> 本次实验项目基于debian 9系统进行构建，以下涉及到的一些安装命令请根据自己具体环境自行替换

## 二、安装
#### 1. 安装node
```bash
wget https://nodejs.org/dist/v10.16.3/node-v10.16.3-linux-x64.tar.xz
xz -d node-v10.16.3-linux-x64.tar.xz
tar xvf node-v10.16.3-linux-x64.tar

# 然后将文件夹移动到你需要的地方，设置环境变量PATH即可
mv node-v10.16.3-linux-x64 /usr/local/node-v10.16.3
# 这里使用软链进行设置l
ln -sf /usr/local/node-v10.16.3/bin/node /usr/local/bin/
ln -sf /usr/local/node-v10.16.3/bin/npm /usr/local/bin/

# 设置好后进行测试
node --version
npm --version

```
#### 2. 安装python3，pip
```bash
# 打开下载地址 https://www.python.org/downloads/source/
# 选择适合自己的包下载
wget https://www.python.org/ftp/python/3.7.4/Python-3.7.4.tar.xz
xz -d Python-3.7.4.tar.xz
tar xvf Python-3.7.4.tar

# 进入目录进行安装
cd Python-3.7.4
./configure # 这里可以通过--prefix来指定安装目录
make && make install

# 确认是否安装成功
python3 -V

# 确认安装成功后，安装pip
curl https://bootstrap.pypa.io/get-pip.py | sudo python3

# 确认是否安装成功
pip --version

```
#### 3. 安装django
```bash
pip install django
# 或者通过指定版本进行安装
pip install django==1.11.13

```
#### 4. 安装vue-cli
```bash
npm install -g @vue/cli
# 确认是否安装成功
vue --version

```
> 具体安装方法可见[https://cli.vuejs.org/zh/guide/installation.html](https://cli.vuejs.org/zh/guide/installation.html)

#### 5. 安装mysql
mysql社区版本下载地址
- [https://downloads.mysql.com/archives/](https://downloads.mysql.com/archives/)
- [https://downloads.mysql.com/archives/community/](https://downloads.mysql.com/archives/community/)

1. 安装mysql server
详细安装见[/mysql/mysql-5.7-installation](/mysql/mysql-5.7-installation)

2. 在安装完mysql后，安装相应的驱动mysqlclient
```bash
pip3 install mysqlclient

```

## 三、开始
### 1. 构建python后端框架
#### 1. 使用如下命令构建项目
```bash
django-admin startproject myproject
```
#### 2. 进入项目根目录，创建app，这里app名称叫backend，意思是后端
```bash
python3 manage.py startapp backend
```
#### 3. 在myproject下的settings.py中，将sqlite3数据库配置替换成我们的mysql配置
# 相关配置可以参考地址[https://docs.djangoproject.com/en/2.2/ref/settings/#std:setting-DATABASES](https://docs.djangoproject.com/en/2.2/ref/settings/#std:setting-DATABASES)
```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'mydatabase',
        'USER': 'mydatabaseuser',
        'PASSWORD': 'mypassword',
        'HOST': '127.0.0.1',
        'PORT': '5432',
    }
}

# 并将我们的app，即backend加入到installed_apps列表中
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
     'backend',
]

# 将时区修改为你需要的时区，默认是UTC
TIME_ZONE = 'Asia/Shanghai'

```
#### 4. 在backend目录下的models.py里我们简单写一个model，作为测试:
```python
# -*- coding: utf-8 -*-
from __future__ import unicode_literals
from django.db import models

# Create your models here.
class ChinaCities(models.Model):
    city_name = models.CharField(max_length=255)
    city_code = models.IntegerField(default=0)
    create_time = models.DateTimeField(auto_now_add=True)

    def __unicode__(self):
        return self.city_name
```
有三个字段，城市名称、城市代码和添加时间，如果没有指定主键的话django会自动新增id作为主键。

#### 5. 接口
在backend目录下的views里我们新增两个接口，
一个是city_list返回所有城市列表（通过jsonResponse返回能被前端标识的json格式数据），
二是add_city，接收一个get请求，往数据库里添加一条city数据：
```python
from django.shortcuts import render
from django.views.decorators.http import require_http_methods
from django.core import serializers
from django.http import JsonResponse
import json

from .models import ChinaCities
# Create your views here.

@require_http_methods(["GET"])
def add_city(request):
    response = {}
    try:
        city = ChinaCities(city_name=request.GET.get('city_name'), city_code=request.GET.get('city_code'))
        city.save()
        response['message'] = 'success'
        response['code'] = 100
    except Exception as e:
        response['message'] = str(e)
        response['code'] = 99

    return JsonResponse(response) # 注意这里要对齐

@require_http_methods(["GET"])
def city_list(request):
    response = {}
    try:
        cities = ChinaCities.objects.filter()
        response['data'] = json.loads(serializers.serialize("json", cities))
        response['message'] = 'success'
        response['code'] = 100

    except Exception as e:
        response['message'] = str(e)
        response['code'] = 99

    return JsonResponse(response) # 注意这里要对齐

```
以上是ORM的使用

#### 6. 在backend目录下，新增一个urls.py文件，用于添加路由：
```python
from django.conf.urls import url, include
from . import views

urlpatterns = [
    url(r'add_city$', views.add_city, ),
    url(r'city_list$', views.city_list, ),
]
```
最后将上面的路由添加到myproject项目下的urls中
```python
import backend.urls # 导入

urlpatterns = [
    url(r'^admin/', admin.site.urls),
    url(r'api/', include(backend.urls)), # 添加路由
    url(r'', TemplateView.as_view(template_name="index.html")),
]

```
到此路由配置完毕，运行如下初始化数据库命令
```bash
python3 manage.py makemigrations backend

python3 manage.py migrate

```
查询数据库，发现已经初始化好了数据表

### 2. 构建vue.js前端框架
首先确认是否安装vue-cli脚手架，通过如下命令确认
```bash
vue --version
```
如果未安装可以通过如下命令安装
```bash
npm install -g @vue/cli
```

#### 首先在整个项目根目录，即backend同级目录下，新建一个vue项目叫frontend
```bash
# vue-cli 2.x的使用如下命令创建项目
vue-init webpack frontend # 安装过程中，可选手动选择安装组件，有些可选组件如vue-router，vuex等可以根据自己需要确定是否安装

# vue-cli 3.x的使用如下命令创建项目
vue create frontend

```
> 具体更多命令可见[https://cli.vuejs.org/zh/guide/creating-a-project.html#vue-create](https://cli.vuejs.org/zh/guide/creating-a-project.html#vue-create)


#### 安装element-ui框架和vue-resource(http请求等相关包)相关依赖包
```bash
cd frontend
npm install
npm install element-ui
npm install vue-resource

```
#### 在src/main.js下配置vue加载组件
```js
import VueResource from "vue-resource"
import ElementUI from "element-ui"
import "element-ui/lib/theme-chalk/index.css"

Vue.use(VueResource);
Vue.use(ElementUI);

```

#### 在src/component文件夹下新建一个组件叫Home.vue，然后写上用于添加城市信息的代码
```html
<template>
  <div class="home">
    <el-row display="margin-top:10px">
      <el-col :span="4"><el-input v-model="name" placeholder="请输入城市名称"></el-input></el-col>
      <el-col :span="4"><el-input v-model="code" placeholder="请输入城市代码"></el-input></el-col>
      <el-button type="primary" @click="addCity(name, code)">新增城市</el-button>
    </el-row>
    <el-row>
      <el-table :data="cityList" style="width: 100%" border>
        <el-table-column prop="id" label="编号" min-width="100">
          <template scope="scope">{{ scope.row.pk }}</template>
        </el-table-column>
        <el-table-column prop="city_name" label="城市名称" min-width="100">
          <template scope="scope">{{ scope.row.fields.city_name }}</template>
        </el-table-column>
         <el-table-column prop="city_code" label="城市代码" min-width="100">
          <template scope="scope">{{ scope.row.fields.city_code }}</template>
        </el-table-column>
         <el-table-column prop="create_time" label="创建时间" min-width="100">
          <template scope="scope">{{ scope.row.fields.create_time }}</template>
        </el-table-column>
      </el-table>
    </el-row>
  </div>
</template>

<script>
// @ is an alias to /src

export default {
  name: 'home',
  data(){
    return {
      name: "",
      code: 0,
      cityList: [],
    }
  },
  methods:{
    fetchList(){
      this.$http.get("/api/city_list").then(res => {
        console.log(res.body);
          if(res.body.code == 100){
              this.$message({
                type: "success",
                showClose: true,
                message: "加载成功",
              });
            this.cityList = res.body.data;
          }else{
            this.$message({
                type: "error",
                showClose: true,
                message: "加载失败",
              });
          }
      })
    },
    addCity(name, code){
      let options = {
        params: {
          "city_name": name,
          "city_code": code
        },
        emulateJSON: true,
      };
      this.$http.get("/api/add_city", options).then(res => {
          console.log(res.body);
          if(res.body.code == 100){
            this.$message({
                type: "success",
                showClose: true,
                message: "添加成功",
              });
            this.fetchList();
          }else{
            this.$message({
                type: "error",
                showClose: true,
                message: "添加失败",
              });
          }
      })
    }
  },
  mounted() {
    this.fetchList();
  }
}
</script>

```

#### 添加路由
在src/router.js下新增路由
```js
import Home from './views/Home.vue'

export default new Router({
  mode: 'history',
  base: process.env.BASE_URL,
  routes: [
    {
      path: '/',
      name: 'home',
      component: Home
    },
  ]
})
```
路由添加好了，可以运行下是否正常了


#### 在frontend目录下运行npm run dev启动node服务器，在浏览器中打开地址
```bash
npm run dev
```
#### 如果一切正常，我们可以使用如下命令构建打包所有资源到dist目录下
因为我们下面配置静态资源路径多路一个static前缀，所以我们在运行下面的命令时候，先配置frontend/vue.config.js，
以使打包的静态资源放到static目录下
```js
module.exports = {
  lintOnSave: false,
  assetsDir: 'static',  // 指定`build`时,在静态文件上一层添加static目录
}
```
然后运行打包命令
```bash
npm run build
```

## 四、整合前后端
前面构建好的前后端框架实际上都是各自运行在自己的服务器中，如果我们向通过python解析运行前后端代码，
则需要将Django的TemplateView指向我们刚才生成的前端dist文件即可，具体配置如下：

#### 1. 找到myproject目录下的urls.py，使用通用试图创建最简单的模板控制器，访问根目录直接返回index.html
```python
from django.contrib import admin
from django.urls import path
from django.views.generic.base import TemplateView //注意加上这句

urlpatterns = [
    path('admin/', admin.site.urls),
    path(r'', TemplateView.as_view(template_name="index.html")), # 添加这行
]

```
#### 2. 使用django进行模板解析，需要配置一下django具体要在哪里找到index.html。
因为前面vue项目打包的时候已经配置了静态资源的路径在dist/static目录下，所以直接进行如下配置即可
```python
# 在myproject目录的settings.py下
TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': ['frontend/dist'], # 修改这句
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

# 配置静态文件搜索路径，在同时myproject下的settings.py添加如下整段内容：
STATICFILES_DIRS = [
    os.path.join(BASE_DIR, "frontend/dist/static/"),
]


# 在myproject/settings.py下确认静态路径配置是否如下
STATIC_URL = '/static/'
```

#### 3. 到这里我们基本配置完成，可以运行如下命令查看整个项目
```bash
python3 manage.py runserver 8080

```



