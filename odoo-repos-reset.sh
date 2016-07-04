#!/bin/bash
if [ -z "$HOME" ]; then
    echo "ERROR: Instalation error, HOME is not defined"
    exit 1
fi

show_error() {
    error=$1
    output=$2

    echo "ERROR: $error";
    echo "----------------------------------------------------------------"
    cat $output
    echo "----------------------------------------------------------------"
    rm -rf $output
}

repo_reset() {
    name=$1

    temp=/tmp/odoo_repos_reset.$$.tmp
    branch=$(expr $(git -C $(pwd)/$name symbolic-ref HEAD) : 'refs/heads/\(.*\)')
    remote=$(git -C $(pwd)/$name config branch.$branch.remote)
    remote_branch=$(expr $(git -C $(pwd)/$name config branch.$branch.merge) : 'refs/heads/\(.*\)')
    status=''
    git -C $(pwd)/$name status --porcelain > $temp 2>&1
    if [ -n "$(cat $temp)" ]; then status='DIRTY'; fi

    if [ "$status" == 'DIRTY' ]; then
        echo "[?] $name is dirty:"
        echo "----------------------------------------------------------------"
        cat $temp
        echo "----------------------------------------------------------------"
    elif [ -z "$remote" ] || [ -z "$remote_branch" ]; then
        echo "[?] $name has no tracking branch: remote = '$remote', remote_branch = '$remote_branch'"
    else
        printf "[ ] %-28s - Checkout to %s:%s ... " "$name" "$remote" "$remote_branch"
        git -C $(pwd)/$name checkout $remote/$remote_branch > $temp 2>&1
        error=$?; if [ $error -ne 0 ]; then show_error $error $temp; return $error; fi
        echo "OK"
    fi
    rm -rf $temp
}

odoo_reset() {
    cd $HOME
    if [ -d $HOME/OCB/.git ]; then
        repo_reset OCB
    elif [ -d $HOME/odoo/.git ]; then
        repo_reset odoo
    fi
}

repo="$1"

if [ -z "$repo" ]; then
    if [ -d $HOME/repos ]; then
        cd $HOME/repos
        for repo in $(find -maxdepth 2 -type d -name ".git" -printf '%h\n' | sort); do
            name=${repo#./}
            repo_reset $name
        done
    fi
    odoo_reset
else
    if [ "$repo" == 'odoo' ]; then
        odoo_reset
    elif [ -d $HOME/repos/$repo/.git ]; then
        cd $HOME/repos
        repo_reset $repo
    elif [ -d $HOME/$repo/.git ]; then
        cd $HOME
        repo_reset $repo
    elif [ -d $repo/.git ]; then
        cd $(dirname $repo)
        repo_reset $(basename $repo)
    else
        echo "ERROR: Repo '$repo' not found"
    fi
fi
