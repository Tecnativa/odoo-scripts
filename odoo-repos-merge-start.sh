#!/bin/bash
if [ -z "$HOME" ]; then
    echo "ERROR: Instalation error, HOME is not defined"
    exit 1
fi

show_help() {
    echo "ERROR: $2"
    echo "Usage: $0 <repo>"
    exit $1
}

repo="$1"
if [ -z "$repo" ]; then
    show_help 1 "No repo defined"
fi

merge_start() {
    name=$1

    temp=/tmp/odoo_repos_merge_start.$$.tmp
    branch=$(expr $(git -C $(pwd)/$name symbolic-ref HEAD) : 'refs/heads/\(.*\)')
    remote=$(git -C $(pwd)/$name config branch.$branch.remote)
    remote_branch=$(expr $(git -C $(pwd)/$name config branch.$branch.merge) : 'refs/heads/\(.*\)')
    status=''
    git -C $(pwd)/$name status --porcelain > $temp 2>&1
    if [ -n "$(cat $temp)" ]; then status='DIRTY'; fi

    if [ "$status" == 'DIRTY' ]; then
        show_error "$name is dirty" $temp
    elif [ -z "$remote" ] || [ -z "$remote_branch" ]; then
        show_error "$name has no tracking branch: remote = '$remote', remote_branch = '$remote_branch'"
    else
        printf "%-28s - Start merging:\n" "$name"

        all_branch=
        new_branch='merge'

        echo -n "   - Fetch remote '$remote' ... "
        git -C $(pwd)/$name fetch $remote > $temp 2>&1
        error=$?; if [ $error -ne 0 ]; then show_error $error $temp; return $error; fi
        echo "OK"

        echo -n "   - Checkout to '$remote/$remote_branch' ... "
        git -C $(pwd)/$name checkout $remote/$remote_branch > $temp 2>&1
        error=$?; if [ $error -ne 0 ]; then show_error $error $temp; return $error; fi
        echo "OK"

        if git -C $(pwd)/$name branch -l --no-color | egrep -q " $new_branch\$"; then
            echo -n "   - Removing branch '$new_branch' ... "
            git -C $(pwd)/$name branch -D $new_branch > $temp 2>&1
            error=$?; if [ $error -ne 0 ]; then show_error $error $temp; return $error; fi
            echo "OK"
        fi

        echo -n "   - Creating branch '$new_branch' ... "
        git -C $(pwd)/$name branch $new_branch $remote/$remote_branch > $temp 2>&1
        error=$?; if [ $error -ne 0 ]; then show_error $error $temp; return $error; fi
        echo "OK"

        echo -n "   - Checkout to '$new_branch' ... "
        git -C $(pwd)/$name checkout --force $new_branch > $temp 2>&1
        error=$?; if [ $error -ne 0 ]; then show_error $error $temp; return $error; fi
        echo "OK"

        echo -n "   - Reseting hard to '$remote/$remote_branch' ... "
        git -C $(pwd)/$name reset --hard $remote/$remote_branch > $temp 2>&1
        error=$?; if [ $error -ne 0 ]; then show_error $error $temp; return $error; fi
        echo "OK"
    fi

    rm -rf $temp
}

odoo_merge_start() {
    cd $HOME
    if [ -d $HOME/OCB/.git ]; then
        merge_start OCB
    elif [ -d $HOME/odoo/.git ]; then
        merge_start odoo
    fi
}

if [ "$repo" == 'odoo' ]; then
    odoo_merge_start $@
elif [ -d $HOME/repos/$repo/.git ]; then
    cd $HOME/repos
    merge_start $@
elif [ -d $HOME/$repo/.git ]; then
    cd $HOME
    merge_start $@
elif [ -d $repo/.git ]; then
    cd $(dirname $repo)
    merge_start $(basename $repo) ${@:2}
else
    show_help 2 "Repo '$repo' not found"
fi
