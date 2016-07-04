#!/bin/bash
if [ -z "$HOME" ]; then
    echo "ERROR: Instalation error, HOME is not defined"
    exit 1
fi

show_help() {
    echo "ERROR: $2"
    echo "Usage: $0 <repo> <pr> <remote> <remote_url> <remote_branch>"
    exit $1
}
if [ ! $# -eq 5 ]; then
    show_help 1 "Bad params"
fi

repo="$1"

show_error() {
    error=$1
    output=$2

    echo "ERROR: $error";
    if [ -n "$output" ] && [ -f $output ]; then
        echo "----------------------------------------------------------------"
        cat $output
        echo "----------------------------------------------------------------"
        rm -rf $output
    fi
}

merge_branch() {
    name=$1
    pr=$2
    merge_remote=$3
    merge_remote_url=$4
    merge_remote_branch=$5

    temp=/tmp/odoo_repos_merge_branch.$$.tmp
    branch=$(expr $(git -C $(pwd)/$name symbolic-ref HEAD) : 'refs/heads/\(.*\)')
    remote=$(git -C $(pwd)/$name config branch.$branch.remote)
    remote_branch=$(expr $(git -C $(pwd)/$name config branch.$branch.merge) : 'refs/heads/\(.*\)')
    status=''
    git -C $(pwd)/$name status --porcelain > $temp 2>&1
    if [ -n "$(cat $temp)" ]; then status='DIRTY'; fi

    if [ "$status" == 'DIRTY' ]; then
        show_error "$name is dirty" $temp
    elif ! echo "$branch" | egrep -q "^merge"; then
        show_error "$name is not in a merge branch. Run 'odoo-repos-merge-start' first"
    elif [ -z "$remote" ] || [ -z "$remote_branch" ]; then
        show_error "$name has no tracking branch: remote = '$remote', remote_branch = '$remote_branch'"
    else
        printf "%-28s - Merging branch: [%s] %s/%s\n" "$name" "$pr" "$merge_remote" "$merge_remote_branch"

        new_branch="${branch}_${pr}"

        if ! git -C $(pwd)/$name remote | egrep -q "^$merge_remote\$"; then
            echo -n "   - Adding remote '$merge_remote' ($merge_remote_url) ... "
            git -C $(pwd)/$name remote add $merge_remote $merge_remote_url > $temp 2>&1
            error=$?; if [ $error -ne 0 ]; then show_error $error $temp; return $error; fi
            echo "OK"
        fi

        echo -n "   - Fetch remote '$merge_remote' ... "
        git -C $(pwd)/$name fetch $merge_remote > $temp 2>&1
        error=$?; if [ $error -ne 0 ]; then show_error $error $temp; return $error; fi
        if ! git -C $(pwd)/$name branch -a --no-color | egrep -q "remotes/$merge_remote/$merge_remote_branch\$"; then
            show_error "Branch remotes/$merge_remote/$merge_remote_branch not found" $temp; return 3
        fi
        echo "OK"

        if git -C $(pwd)/$name branch -l --no-color | egrep -q " $new_branch\$"; then
            echo -n "   - Removing branch '$new_branch' ... "
            git -C $(pwd)/$name branch -D $new_branch > $temp 2>&1
            error=$?; if [ $error -ne 0 ]; then show_error $error $temp; return $error; fi
            echo "OK"
        fi

        echo -n "   - Renaming branch '$branch' to '$new_branch' ... "
        git -C $(pwd)/$name branch -m $new_branch > $temp 2>&1
        error=$?; if [ $error -ne 0 ]; then show_error $error $temp; return $error; fi
        echo "OK"

        echo -n "   - Merging '$merge_remote/$merge_remote_branch' ... "
        git -C $(pwd)/$name merge --no-edit $merge_remote/$merge_remote_branch > $temp 2>&1
        error=$?; if [ $error -ne 0 ]; then show_error $error $temp; return $error; fi
        echo "OK"
    fi

    rm -rf $temp
}

odoo_merge_branch() {
    cd $HOME
    if [ -d $HOME/OCB/.git ]; then
        merge_branch OCB ${@:2}
    elif [ -d $HOME/odoo/.git ]; then
        merge_branch odoo ${@:2}
    fi
}

if [ "$repo" == 'odoo' ]; then
    odoo_merge_branch $@
elif [ -d $HOME/repos/$repo/.git ]; then
    cd $HOME/repos
    merge_branch $@
elif [ -d $HOME/$repo/.git ]; then
    cd $HOME
    merge_branch $@
elif [ -d $repo/.git ]; then
    cd $(dirname $repo)
    merge_branch $(basename $repo) ${@:2}
else
    show_help 2 "Repo '$repo' not found"
fi
