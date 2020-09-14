---
title: "windows下Vscode Php开发环境配置"
date: 2020-09-14T17:08:59+08:00
keywords: ["posts", "vscode"]
categories: ["posts"]
tags: ["posts", "vscode", "php"]
series: [""]
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

## 准备
- windows10 系统
- vscode
- xampp

### 首先下载安装xampp
由于墙的问题，可以使用如下地址：[https://sourceforge.net/projects/xampp/](https://sourceforge.net/projects/xampp/)

当然如果你能翻墙，可以直接访问xampp官网下载

下载完成后安装，安装完成后，将xampp/php/php.exe加入系统路径,
在terminal中执行php -v验证是否成功

### 下载xdebug插件
下载地址：[https://xdebug.org/download](https://xdebug.org/download)

如果不知道下载什么版本，可以将你的phpinfo信息拷贝到这个网址下查询[https://xdebug.org/wizard](https://xdebug.org/wizard)
复制后点击下面的分析phpinfo按钮

这里下载的是：https://xdebug.org/files/php_xdebug-2.9.6-7.4-vc15-x86_64.dll

#### 将下载好的拷贝到xampp/php/ext文件夹中
#### 修改php.ini文件，在文件末尾追加以下信息
[xdebug]
zend_extension="E:\xampp\php\ext\php_xdebug-2.9.6-7.4-vc15-x86_64.dll"
xdebug.remote_enable = 1
xdebug.remote_autostart = 1
xdebug.remote_port = 9900    //  默认端口9000，根据自己本机改                   
xdebug.remote_handler = dbgp
xdebug.remote_host = 127.0.0.1

### vscode下载安装
下载vscode：[https://code.visualstudio.com/](https://code.visualstudio.com/)

下载安装完成后，需要安装一些扩展插件

- bmewburn.vscode-intelephense-client
- felixfbecker.php-intellisense
- felixfbecker.php-debug
- ikappas.composer

按下ctrl+p，然后输入> settings.json，选择preferences: open default settings(JSON),
打开配置文件，配置php执行路径：
```shell script
"php.validate.executablePath": "E:\\xampp\\php\\php.exe"
```
### 准备好后开始测试
在xampp/htdocs/目录下新建一个php文件夹，然后在用vscode打开php文件夹，新建文件php_test.php，内容如下：
```php
<?php
$a = 'hello world';
echo $a;
?>
```
在 "$a = 'hello world'"这一行设置断点，
然后，按下f5执行，转到run code的界面，如果是首次运行，需要配置configuration，因为左上角显示的是
No Configuration，

这时需要点击其右侧的小齿轮（应该有个红点），点击后会弹出命令面板让你选择语言环境，
选择PHP后，会自动配置好.vscode/launch.json

其内容大致如下：
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Listen for XDebug",
            "type": "php",
            "request": "launch",
            "port": 9000
        }

    ]
}
```

保存后，还是在RUN Code界面的左上角选择Listen for XDebug即可调试测试了





