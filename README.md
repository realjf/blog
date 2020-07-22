# blog

## 安装hugo
```
go get -u -v github.com/gohugoio/hugo
```

## hugo命令
| 命令 | 说明 |
| ---| --- |
|hugo new site /path/to/site | 生成站点 |
|hugo new about.md| 生成文章 |
| hugo new post/first.md| 创建 post目录下的文章|
| hugo server --theme=m10c --buildDrafts -w| 运行hugo站点, -w监视文件变化，--buildDrafts草稿可见|



#### hugo站点目录结构
```
archetypes/ #存放default.md，头文件格式
content/ #content目录存放博客文章（.markdown/.md文件）
layouts/ #layouts目录存放的是网站的模板文件
static/ #存放js/css/img等静态资源
content # 存放 markdown 文件
config.toml #网站的配置文件
```


## gitpages构建和部署
```bash
cd blog

# delete old publication
rm -rf public
mkdir public
git worktree prune

# checking out gh-pages branch into public
git worktree add -B gh-pages public origin/gh-pages
# 利用hugo生成静态文件
hugo -t m10c
# 提交更新gh-pages branch
cd public
git add --all
git commit -m "update"
cd ..
# 推送到仓库
git push origin gh-pages

```
