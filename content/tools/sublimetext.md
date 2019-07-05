---
title: "Sublimetext debian安装与常用插件配置"
date: 2019-07-05T10:27:14+08:00
draft: false
---

> sublime text官网[http://www.sublimetext.com](http://www.sublimetext.com)

## 安装
#### install the GPG key
```bash
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
```

#### 确保apt工作在http源
```bash
apt-get install apt-transport-https
```
#### 选择安装渠道
稳定版本
```bash
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
```
开发版本
```bash
echo "deb https://download.sublimetext.com/ apt/dev/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
```
#### 更新源并安装
```bash
apt-get update
apt-get install sublime-text
```

## 安装常用插件
#### 1. 安装Package Control
请参考网址[Install Package Control](https://packagecontrol.io/)

#### 2. 常用插件
##### ConvertToUTF8 
功能：能将除UTF8编码之外的其他编码文件在 Sublime Text 中转换成UTF8编码，在打开文件的时候一开始会显示乱码，然后一刹那就自动显示出正常的字体，当然，在保存文件之后原文件的编码格式不会改变

##### BracketHighlighter
功能：高亮显示匹配的括号、引号和标签。

##### Emmet
功能：前端开发必备，HTML、CSS代码快速编写神器

##### JsFormat
功能：javascript代码格式化

##### ColorHighlighter
功能：显示所选颜色值的颜色，并继承了colorpicker

##### Compact Expand CSS Command
功能：格式化css代码
插件地址：[https://github.com/TooBug/CompactExpandCss](https://github.com/TooBug/CompactExpandCss)

##### SublimeTmpl
功能：快速生成文件魔板

##### Alignment
功能：使代码自动对齐

##### AutoFileName
功能：自动补全文件名

##### autoprefixer
功能：css前缀自动补全匹配

##### DocBlockr
功能：快速生成JavaScript (including ES6), PHP, ActionScript, Haxe, CoffeeScript, TypeScript, Java, Groovy, Objective C, C, C++ and Rust语言函数注释

##### SublimeCodeIntel
功能：代码智能提示

##### SideBarEnhancements
功能：侧边栏菜单扩充功能

##### View In Browser
功能：Sublime Text保存后网页自动同步更新

##### LiveReload
功能：调试网页实时自动更新
> 同时Chrome浏览器也要安装LiveReload 的扩展插件


## 移除插件
1. 快捷键 Ctrl+Shift+P，在对话框中输入“remove”，选择“Package Control: Remove Packages”
2. 选择你要移除的插件即可


## 快捷键汇总
1、通用

      ↑↓← →    上下左右移动光标

      Alt    调出菜单

      Ctrl + Shift + P    调出命令板（Command Palette）

      Ctrl + `    调出控制台

2、编辑

      Ctrl + Enter    在当前行下面新增一行然后跳至该行

      Ctrl + Shift + Enter    在当前行上面增加一行并跳至该行

      Ctrl + ←/→    进行逐词移动

      Ctrl + Shift + ←/→    进行逐词选择

      Ctrl + ↑/↓    移动当前显示区域

      Ctrl + Shift + ↑/↓    移动当前行

3、选择

      Ctrl + D    选择当前光标所在的词并高亮该词所有出现的位置，再次 Ctrl + D 选择该词出现的下一个位置，在多重选词的过程中，使用 Ctrl + K 进行跳过，使用 Ctrl + U 进行回退，使用 Esc 退出多重编辑

      Ctrl + Shift + L    将当前选中区域打散

      Ctrl + J    把当前选中区域合并为一行

      Ctrl + M    在起始括号和结尾括号间切换

      Ctrl + Shift + M    快速选择括号间的内容

      Ctrl + Shift + J    快速选择同缩进的内容

     Ctrl + Shift + Space    快速选择当前作用域（Scope）的内容

4、查找&替换

      F3    跳至当前关键字下一个位置

      Shift + F3    跳到当前关键字上一个位置

      Alt + F3    选中当前关键字出现的所有位置

      Ctrl + F/H    进行标准查找/替换，之后：

      Alt + C    切换大小写敏感（Case-sensitive）模式

      Alt + W    切换整字匹配（Whole matching）模式

      Alt + R    切换正则匹配（Regex matching）模式

      Ctrl + Shift + H    替换当前关键字

      Ctrl + Alt + Enter    替换所有关键字匹配

      Ctrl + Shift + F    多文件搜索&替换

5、跳转

      Ctrl + P    跳转到指定文件，输入文件名后可以：

      @ 符号跳转    输入@symbol跳转到symbol符号所在的位置

      # 关键字跳转    输入#keyword跳转到keyword所在的位置

      : 行号跳转    输入:12跳转到文件的第12行。

      Ctrl + R    跳转到指定符号

      Ctrl + G    跳转到指定行号

6、窗口

      Ctrl + Shift + N    创建一个新窗口

      Ctrl + N    在当前窗口创建一个新标签

      Ctrl + W    关闭当前标签，当窗口内没有标签时会关闭该窗口

      Ctrl + Shift + T    恢复刚刚关闭的标签

7、屏幕

      F11    切换至普通全屏

      Shift + F11    切换至无干扰全屏

      Alt+Shift+1       Single             切换至独屏

      Alt+Shift+2       Columns:2      切换至纵向二栏分屏

      Alt+Shift+3       Columns:3      切换至纵向三栏分屏

      Alt+Shift+4       Columns:4      切换至纵向四栏分屏

      Alt+Shift+8       Rows:2          切换至横向二栏分屏

      Alt+Shift+9       Rows:3          切换至横向三栏分屏

      Alt+Shift+5       Grid              切换至四格式分屏