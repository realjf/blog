#!/bin/bash

echo -e "\033[0;32mPushing updates to GitHub...\033[0m"

git pull
rm -rf public
git add -A
git commit -m "updates"
git push origin master

echo -e "\033[0;32mDone\033[0m"
