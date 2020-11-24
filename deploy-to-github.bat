@echo off
echo "Deploying updates to GitHub..."

rem update
git pull

rem init public
rmdir /s /Q public
mkdir public
git worktree prune

rem checking out gh-pages branch into public
git worktree add -B gh-pages public origin/gh-pages
rem hugo generate static files
hugo -t m10c
rem commit updates to gh-pages branch
cd public
git add --all
git commit -m "update"
cd ..
rem push to repo
git push origin gh-pages

echo "done"