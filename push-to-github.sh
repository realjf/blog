#!/bin/bash

echo -e "\033[0;32mPushing updates to GitHub...\033[0m"

rm -rf public
git add -A
git commit -m "updates"
git push origin master

echo "\033[0;32mDone\033[0m"
