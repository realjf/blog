@echo off
echo "Deploying updates to GitHub..."

rem update
git pull

rem init public
rmdir /s public
mkdir public
git worktree prune

rem checking out gh-pages branch into public
git worktree add -B gh-pages public origin/gh-pages
rem 利用hugo生成静态文件
hugo -t m10c
rem 提交更新gh-pages branch
cd public
git add --all
git commit -m "update"
cd ..
rem 推送到仓库
git push origin gh-pages

echo "done"