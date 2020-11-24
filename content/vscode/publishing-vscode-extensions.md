---
title: "VS Code扩展开发 之 发布扩展 Publishing Vscode Extensions"
date: 2020-11-24T14:03:58+08:00
keywords: ["vscode", "extension"]
categories: ["vscode"]
tags: ["vscode"]
series: [""]
draft: false
toc: false
related:
  threshold: 50
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

一旦你制作了高质量的扩展，你就能发布到vscode 扩展市场，以便让其他人可以找到并下载使用你的扩展，
你可以打包扩展为可安装的VSIX格式并与其他人分享

本节将包括以下内容：

- 使用vsce，这个是管理VS Code扩展的CLI工具
- 打包、发布以及取消发布扩展
- 注册一个发布者id用于发布扩展

### vsce
vsce，是Visual Studio Code Extensions的简称，是一个打包，发布和管理vscode扩展的命令行工具

#### 安装
请确保你已经安装了node.js
```shell script
npm install -g vsce
```

#### 使用
```shell script
cd myExtension
vsce package
# myExtension.vsix generated
vsce publish
# <publisherID>.myExtension published to VS Code MarketPlace
```
更多的命令请使用vsce --help查看

## 发布扩展
> 由于安全考虑，vsce不会发布包含用户提供的svg图片的扩展

发布工具检查如下内容：

- package.json中提供的icon图标可能不是一个svg
- package.json中提供的徽章可能不是svg，除非他们来自可信的徽章提供商
- README.md和CHANGELOG.md中的图片地址需要处理成https路径
- README.md中和CHANGELOG.md中的图片可能不是svg除非他们来自可信的徽章提供商

visualstudio代码利用[Azure DevOps](https://azure.microsoft.com/services/devops/)提供其Marketplace服务。
这意味着扩展的身份验证、托管和管理是通过azuredevops提供的。

vsce只能使用Personal access tokens发布扩展。要发布扩展，至少需要创建一个，

### 获取个人access token
首先，确保你有Azure DevOps[组织](https://docs.microsoft.com/zh-cn/azure/devops/organizations/accounts/create-organization?view=azure-devops)

1. 在下面的示例中，组织的名称是realjf。从组织的主页（例如：https://dev.azure.com/realjf)下一步，
打开“个人图像设置”下拉菜单，选择Personal access tokens：

2. 在Personal Access Tokens页面，点击New Token创建一个新的Personal Access Token

3. 给Personal Access Token命名，选择所有organization可用，过期日期自定义选择一年，然后往下选择custom defined域规则，并点击Show all scopes显示所有域

4. 最后，往下滚动直到你找到Marketplace并勾选Manage和Acquire

5. 以上勾选完毕后，选择创建，之后你将看到新建好的Personal Access Token，复制它，作为后续创建发布者用

### 创建一个发布者
每一个扩展需要在package.json文件中包含发布者名字

一旦你有Personal Access Token，你就能创建一个新的发布者使用vsce
```shell script
vsce create-publisher (publisher name)
```
vsce会记住当前提供的Personal Access Token作为未来这个发布者使用

> 或者，在Marketplace发布者管理页面中创建发布者，并通过vsce登录，如下一节所述。

### 登录发布者
如果你已经创建了一个发布者，并想通过vsce使用它
```shell script
vsce login (publisher name)
```
与create-publisher命令相似，vsce会问你Personal Access Token以及记住它作为之后命令使用

你也可以输入你的Personal Access Token，通过参数-p <token>指定一个
```shell script
vsce publish -p <token>
```

## 查看扩展安装和分级
您可以访问管理发布者和扩展页面，查看您的扩展在市场上的表现
https://marketplace.visualstudio.com/manage/publisher/{publisher-ID}，
在URL中提供您的publisher-ID。在这里，您将看到在您的publisher ID下发布的所有扩展，
并可以选择一个扩展来查看随时间推移的收购趋势，以及总的收购计数和评级和评论。

## 扩展版本的自增
发布时，可以通过指定要递增的[SemVer](https://semver.org/)兼容号：major、minor或patch来自动递增扩展的版本号

例如，你想更新扩展的版本从1.0.0到1.1.0，你可以指定minor：
```shell script
vsce publish minor
```
这个会在发布扩展之前修改扩展的package.json版本属性

你也可以在命令行中指定一个完整的SemVer兼容版本
```shell script
vsce publish 2.0.1
```
> 如果vsce publish在一个git仓库运行，它也会创建一个版本commit和tag甚至npm-version，
> 默认commit信息是扩展的版本，但是你可以提供自定义信息，使用-m标志指定

## 取消发布扩展
如果你想在本地安装的vscode中测试扩展或不通过发布到vscode市场分配一个扩展，你可以选择打包你的扩展，
vsce可以打包你的扩展为VSIX文件，你可以通过它很简单的安装上

- 对于扩展作者而言，他们能运行vsce package创建VSIX文件,
- 对于收到VSIX文件的用户，他们可以通过code --install-extension my-extension.0.0.1.vsix安装扩展

## 你的扩展文件夹
为了加载扩展，你需要复制文件到你的vscode扩展文件夹，这个根据平台不同而不同

- Windows： %USERPROFILE%\.vscode\extensions
- macOS：~/.vscode/extensions
- Linux：~/.vscode/extensions

## VSCode 兼容性
当命名一个扩展，你需要描述这个扩展的VSCode兼容性，这个通过package.json指定engines.vscode来处理
```json
{
  "engines": {
    "vscode": "^1.8.0"
  }
}
```

## 预发布阶段
可以将预发布步骤添加到清单文件中。每次打包扩展时都会调用该命令
```json
{
  "name": "uuid",
  "version": "0.0.1",
  "publisher": "someone",
  "engines": {
    "vscode": "0.10.x"
  },
  "scripts": {
    "vscode:prepublish": "tsc"
  }
}
```
每当打包扩展时，这将始终调用TypeScript编译器。






















