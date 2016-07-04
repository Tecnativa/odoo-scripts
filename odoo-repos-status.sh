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
    rm -rf $temp
}

odoo_status() {
    cd $HOME
    if [ -d $HOME/OCB/.git ]; then
        repo_status OCB
    elif [ -d $HOME/odoo/.git ]; then
        repo_status odoo
    fi
}

repo="$1"

if [ -z "$repo" ]; then
    if [ -d $HOME/repos ]; then
        cd $HOME/repos
        for repo in $(find -maxdepth 2 -type d -name ".git" -printf '%h\n' | sort); do
            name=${repo#./}
            repo_status $name
        done
    fi
    odoo_status
else
    if [ "$repo" == 'odoo' ]; then
        odoo_status
    elif [ -d $HOME/repos/$repo/.git ]; then
        cd $HOME/repos
        repo_status $repo
    elif [ -d $HOME/$repo/.git ]; then
        cd $HOME
        repo_status $repo
    elif [ -d $repo/.git ]; then
        cd $(dirname $repo)
        repo_status $(basename $repo)
    else
        echo "ERROR: Repo '$repo' not found"
    fi
fi
