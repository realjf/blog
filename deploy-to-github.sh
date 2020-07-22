#!/bin/bash

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

# update
git pull

# init public
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



