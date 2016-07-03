#!/bin/bash
if [ -z "$HOME" ]; then
    echo "ERROR: Instalation error, HOME is not defined"
    exit 1
fi

repo_status() {
    name=$1

    temp=/tmp/odoo_repos_status.$$.tmp
    branch=$(expr $(git -C $(pwd)/$name symbolic-ref HEAD) : 'refs/heads/\(.*\)')
    remote=$(git -C $(pwd)/$name config branch.$branch.remote)
    remote_branch=$(expr $(git -C $(pwd)/$name config branch.$branch.merge) : 'refs/heads/\(.*\)')
    remote_url=$(git -C $(pwd)/$name remote get-url $remote)
    remote_url_short=$(expr $remote_url : 'https\?://github.com/\(.*\)')
    if [ -z "$remote_url_short" ]; then remote_url_short=$(expr $remote_url : 'https\?://\(.*\)'); fi
    if [ -z "$remote_url_short" ]; then remote_url_short=$(expr $remote_url : 'git@\(.*\)'); fi
    if [ -z "$remote_url_short" ]; then remote_url_short=$remote_url; fi
    last_commit=$(git -C $(pwd)/$name log -n 1 --pretty=format:'%cd %h %an' --date=short)
    commit=${last_commit:0:30}
    git -C $(pwd)/$name status --porcelain > $temp 2>&1
    position=`if [[ $(git -C $(pwd)/$name status --porcelain -b | grep '##') =~ \[(.*)\] ]]; then echo ${BASH_REMATCH[1]}; fi`
    if [ -z "$position" ]; then position='OK'; fi
    if [ -n "$(cat $temp)" ]; then position='DIRTY'; fi

    printf "%-28s - %-30s - %-10s - %-20s - %s\n" "$name" "$commit" "$position" "$branch" "$remote_url_short"
    if [ "$position" == 'DIRTY' ]; then
        echo "----------------------------------------------------------------"
        cat $temp
        echo "----------------------------------------------------------------"
    fi
}

repo="$1"

cd $HOME/repos
if [ -z "$repo" ]; then
    for repo in $(find -maxdepth 2 -type d -name ".git" -printf '%h\n' | sort); do
        name=${repo#./}
        repo_status $name
    done
else
    if [ -d $HOME/repos/$repo ]; then
        if [ -d $HOME/repos/$repo/.git ]; then
            repo_status $repo
        else
            echo "ERROR: Repo '$HOME/repos/$repo' is not a Git repository"
        fi
    else
        echo "ERROR: Repo '$HOME/repos/$repo' not found"
    fi
fi
