---
title: "VSCode扩展开发系列一 之 第一个vscode插件开发 Your First Vscode Extension"
date: 2020-11-24T10:18:41+08:00
keywords: ["vscode"]
categories: ["vscode"]
tags: ["vscode", "extension"]
series: [""]
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
- node.js
- git

## 安装yeoman和vscode扩展生成器
```shell script
npm install -g yo generator-code
```
用生成器构建一个TypeScript或JavaScript项目，以备开发。运行生成器并为TypeScript项目填写一些字段：
```shell script
yo code

? What type of extension do you want to create? New Extension (TypeScript)
? What's the name of your extension? HelloWorld
? What's the identifier of your extension? helloworld
? What's the description of your extension? LEAVE BLANK
? Initialize a git repository? Yes
? Bundle the source code with webpack? No
? Which package manager to use? npm
   create helloworld\.vscode\extensions.json
   create helloworld\.vscode\launch.json
   create helloworld\.vscode\settings.json
   create helloworld\.vscode\tasks.json
   create helloworld\src\test\runTest.ts
   create helloworld\src\test\suite\extension.test.ts
   create helloworld\src\test\suite\index.ts
   create helloworld\.vscodeignore
   create helloworld\.gitignore
   create helloworld\README.md
   create helloworld\CHANGELOG.md
   create helloworld\vsc-extension-quickstart.md
   create helloworld\tsconfig.json
   create helloworld\src\extension.ts
   create helloworld\package.json
   create helloworld\.eslintrc.json


I'm all done. Running npm install for you to install the required dependencies. If this fails, try running the command yourself.


npm notice created a lockfile as package-lock.json. You should commit this file.
npm WARN optional SKIPPING OPTIONAL DEPENDENCY: fsevents@~2.1.2 (node_modules\chokidar\node_modules\fsevents):
npm WARN notsup SKIPPING OPTIONAL DEPENDENCY: Unsupported platform for fsevents@2.1.3: wanted {"os":"darwin","arch":"any"} (current: {"os":"win32","arch":"x64"})
npm WARN helloworld@0.0.1 No repository field.
npm WARN helloworld@0.0.1 No license field.

added 214 packages from 155 contributors and audited 217 packages in 201.89s

29 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities


Your extension helloworld has been created!

To start editing with Visual Studio Code, use the following commands:

     cd helloworld
     code .

Open vsc-extension-quickstart.md inside the new extension for further instructions
on how to modify, test and publish your extension.

For more information, also visit http://code.visualstudio.com and follow us @code.
```
然后运行上面的命令运行扩展
```shell script
cd hellworld
code .
```
然后，在编辑器上按F5，就会在一个新扩展开发主机窗口编译运行这个扩展

运行hello world命令，在命令调色板中(Ctrl+Shift+P)运行该命令，将会在窗口右下角看到如下通知，表明成功
```shell script
Hello World from HelloWorld!
```

## 继续开发扩展
接下来我们将实现如下功能：

- 改变通知信息：Hello World from HelloWorld! 为 Hello VS Code (在extension.ts中修改)
- 在这个新窗口中运行Developer: Reload Window
- 再次运行命令： Hello World

当然你也可以在package.json中的contributes.commands.command中修改命令名称，
还可以修改vscode.window.showInformationMessage为警告信息，具体的[VSCode API](https://code.visualstudio.com/api/references/vscode-api)

## 调试扩展
是需要在需要调试的行中点击边框增加断点就可以进行调试了










