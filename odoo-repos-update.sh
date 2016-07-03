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
}

repo_update() {
    name=$1

    temp=/tmp/odoo_repos_update.$$.tmp
    branch=$(expr $(git -C $(pwd)/$name symbolic-ref HEAD) : 'refs/heads/\(.*\)')
    remote=$(git -C $(pwd)/$name config branch.$branch.remote)
    remote_branch=$(expr $(git -C $(pwd)/$name config branch.$branch.merge) : 'refs/heads/\(.*\)')
    remote_url=$(git -C $(pwd)/$name remote get-url $remote)
    remote_url_short=$(expr $remote_url : 'https\?://github.com/\(.*\)')
    if [ -z "$remote_url_short" ]; then remote_url_short=$(expr $remote_url : 'https\?://\(.*\)'); fi
    if [ -z "$remote_url_short" ]; then remote_url_short=$(expr $remote_url : 'git@\(.*\)'); fi
    if [ -z "$remote_url_short" ]; then remote_url_short=$remote_url; fi
    status=''
    git -C $(pwd)/$name status --porcelain > $temp 2>&1
    if [ -n "$(cat $temp)" ]; then status='DIRTY'; fi

    if echo $branch | egrep -q "^merge_"; then
        echo "[#] $name is in a locally merged branch: $branch"
    elif [ "$status" == 'DIRTY' ]; then
        echo "[?] $name is dirty:"
        echo "----------------------------------------------------------------"
        cat $temp
        echo "----------------------------------------------------------------"
    elif [ -z "$remote" ] || [ -z "$remote_branch" ]; then
        echo "[?] $name has no tracking branch: remote = '$remote', remote_branch = '$remote_branch'"
    else
        printf "[ ] %-28s - Updating from %s:%s ... " "$name" "$remote_url_short" "$remote_branch"
        git -C $(pwd)/$name fetch $remote > $temp 2>&1
        error=$?; if [ $error -ne 0 ]; then show_error $error $temp; return $error; fi
        new_status=`if [[ $(git -C $(pwd)/$name status --porcelain -b | grep '##') =~ \[(.*)\] ]]; then echo ${BASH_REMATCH[1]}; fi`
        if [ -z "$new_status" ]; then
            echo "Up-to-date"
        else
            git -C $(pwd)/$name rebase $remote/$remote_branch > $temp 2>&1
            error=$?; if [ $error -ne 0 ]; then show_error $error $temp; return $error; fi
            echo "OK"
        fi
    fi
}

repo="$1"

cd $HOME/repos
if [ -z "$repo" ]; then
    for repo in $(find -maxdepth 2 -type d -name ".git" -printf '%h\n' | sort); do
        name=${repo#./}
        repo_update $name
    done
else
    if [ -d $HOME/repos/$repo ]; then
        if [ -d $HOME/repos/$repo/.git ]; then
            repo_update $repo
        else
            echo "ERROR: Repo '$HOME/repos/$repo' is not a Git repository"
        fi
    else
        echo "ERROR: Repo '$HOME/repos/$repo' not found"
    fi
fi
