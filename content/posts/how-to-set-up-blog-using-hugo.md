---
title: "How to Set Up Blog Using Hugo"
date: 2019-03-19T09:43:09+08:00
draft: false
---

### github pages有两种方式：
- 一种是<USERNAME>.github.io/
- 另一种是<USERNAME>.github.io/<PROJECT>

我们这里使用第二种方法创建

#### 前期准备
- 有一个github账号


#### 创建一个公开的repo
例如：blog

#### 开通github pages
找到新创建的repo中的settings，往下找到github pages，
如果首次开通，则需要授权一下，授权后，github pages下的source可以选择对应的发布分支。默认为master分支。

**注意**
如果一切正常，github pages选项下有个蓝色提示，显示的是您的博客地址，可以先访问看看是否正常。我这里是：https://realjf.github.io/blog/


#### 配置好后，开始使用hugo构建博客
首先，clone下刚才创建的repo
```sh
git clone git@github.com:<USERNAME>/blog

```

#### 安装hugo，确保repo目录下可以使用hugo命令
请参考官网[https://gohugo.io/](https://gohugo.io/)
```sh
# 检查安装是否成功
hugo version
```

#### 利用hugo构建博客目录结构
```sh
cd blog && hugo new site . --force
```
这里使用了--force是因为当前目录已存在，只是需要初始化而已

#### 添加自己需要的主题
```sh
cd blog
git submodule add https://github.com/realjf/hugo-theme-m10c.git themes/m10c
```
上述的m10c可以换成你想要的主题名字即可

更多的主题请参考：[https://themes.gohugo.io/](https://themes.gohugo.io/)
```sh
# 修改根目录下的 .toml文件
theme = "<THEME>"
baseUrl = "https://realjf.github.io/blog/"
```
<THEME>请修改为你的主题名即可


#### 本地测试博客
```sh
hugo server -t <THEME>
```

#### 到这里，基本的博客搭建完成，先保存到github
```sh
git add -A && git commit -m "Initializing"
git push origin master
```

#### 本地测试成功后，我们利用gh-pages分支作为新的发布分支
gh-pages分支保存的是hugo生成的html静态文件

先把public发布目录添加到.gitignore文件里
```sh
echo "public" >> .gitignore
```

#### 保存到远程repo
```sh
git add -A && git commit -m "add ignore file"
git push origin master
```
#### 初始化gh-pages分支
```sh
git checkout --orphan gh-pages
git reset --hard
git commit --allow-empty -m "Initializing gh-pages branch"
git push origin gh-pages
git checkout master
```

#### 构建和发布
先删除public目录
```sh
rm -rf public
git worktree add -B gh-pages public origin/gh-pages

# 在根目录下构建
hugo -t <THEME>

cd public && git add --all && git commit -m "Publishing to gh-pages"
cd ..
git push origin gh-pages
```

#### 设置gh-pages作为你的发布分支
回到settings里的github pages选项，将source设置为gh-pages分支，等待几分钟后，重新访问博客地址，查看效果是否正常


#### 每次发布hugo的时候，都需要运行以下脚本，以便更新发布
```sh

#!/bin/sh

DIR=$(dirname "$0")

cd $DIR/..

if [[ $(git status -s) ]]
then
    echo "The working directory is dirty. Please commit any pending changes."
    exit 1;
fi

echo "Deleting old publication"
rm -rf public
mkdir public
git worktree prune
rm -rf .git/worktrees/public/

echo "Checking out gh-pages branch into public"
git worktree add -B gh-pages public upstream/gh-pages

echo "Removing existing files"
rm -rf public/*

echo "Generating site"
hugo

echo "Updating gh-pages branch"
cd public && git add --all && git commit -m "Publishing to gh-pages (publish.sh)"

```
最后发布
```sh
git push origin gh-pages
```


