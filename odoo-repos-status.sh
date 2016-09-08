#!/bin/bash
if [ -z "$HOME" ]; then
    echo "ERROR: Instalation error, HOME is not defined"
    exit 1
fi

show_error() {
    local error=$1
    local output=$2

    echo "ERROR: $error";
    if [ -n "$output" ] && [ -f $output ]; then
        echo "----------------------------------------------------------------"
        cat $output
        echo "----------------------------------------------------------------"
        rm -rf $output
    fi
}

repo_status() {
    local name=$1
    local error=0

    local temp=/tmp/odoo_repos_status.$$.tmp
    git -C $(pwd)/$name symbolic-ref HEAD > $temp 2>&1
    error=$?; if [ $error -ne 0 ]; then printf "%-28s - " "$name"; show_error "No HEAD ref"; return $error; fi
    local head=$(cat $temp)
    local branch=$(expr $head : 'refs/heads/\(.*\)')
    local remote=$(git -C $(pwd)/$name config branch.$branch.remote)
    local remote_branch=$(expr $(git -C $(pwd)/$name config branch.$branch.merge) : 'refs/heads/\(.*\)')
    local remote_url=$(git -C $(pwd)/$name remote get-url $remote)
    local remote_url_short=$(expr $remote_url : 'https\?://github.com/\(.*\)')
    if [ -z "$remote_url_short" ]; then remote_url_short=$(expr $remote_url : 'https\?://\(.*\)'); fi
    if [ -z "$remote_url_short" ]; then remote_url_short=$(expr $remote_url : 'git@\(.*\)'); fi
    if [ -z "$remote_url_short" ]; then remote_url_short=$remote_url; fi
    local last_commit=$(git -C $(pwd)/$name log -n 1 --pretty=format:'%cd %h %an' --date=short)
    local commit=${last_commit:0:30}
    git -C $(pwd)/$name status --porcelain > $temp 2>&1
    local position=`if [[ $(git -C $(pwd)/$name status --porcelain -b | grep '##') =~ \[(.*)\] ]]; then echo ${BASH_REMATCH[1]}; fi`
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
    elif [ -d $HOME/openerp/.git ]; then
        repo_status openerp
    fi
}

repo="$1"

if [ -z "$repo" ]; then
    # All repos in home, except Odoo
    for repo in $(find -maxdepth 2 -type d -name ".git" -printf '%h\n' | grep -v '^./odoo$' | grep -v '^./OCB$' | grep -v '^./openerp$' | sort); do
        name=${repo#./}
        repo_status $name
    done
    # All repos in home/repos
    if [ -d $HOME/repos ]; then
        cd $HOME/repos
        for repo in $(find -maxdepth 2 -type d -name ".git" -printf '%h\n' | sort); do
            name=${repo#./}
            repo_status $name
        done
    fi
    # Odoo repo
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
