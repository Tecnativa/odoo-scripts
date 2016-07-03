#!/bin/bash
if [ -z "$HOME" ]; then
    echo "ERROR: Instalation error, HOME is not defined"
    exit 1
fi

repo_status() {
    name=$1

    branch=$(expr $(git -C $(pwd)/$name symbolic-ref HEAD) : 'refs/heads/\(.*\)')
    remote=$(git -C $(pwd)/$name config branch.$branch.remote)
    remote_branch=$(expr $(git -C $(pwd)/$name config branch.$branch.merge) : 'refs/heads/\(.*\)')
    remote_url=$(git -C $(pwd)/$name remote get-url $remote)
    commit=$(git -C $(pwd)/$name log -n 1 --pretty=format:'%cd %h %an' --date=short)
    status=$(git -C $(pwd)/$name --porcelain)
}
