@echo off

echo "Pushing updates to GitHub..."

git pull
rmdir /s public
git add -A
git commit -m "updates"
git push origin master

echo "done"
