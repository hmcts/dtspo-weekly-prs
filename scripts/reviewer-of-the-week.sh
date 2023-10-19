#!/usr/bin/env bash
token=$1

gh auth login --with-token ${token}

ghusers=('JordanHoey96')

for ghuser in ${ghusers[@]}
do
    echo $ghuser
    last100prs=$(gh search prs --reviewed-by $ghuser --json closedAt,url,title --sort updated --limit 10)
    7DaysAgo=$(date --date='7 days ago')
    while read pr; do
        closedDateString=$(jq -r '.closedAt' <<< $pr)
        title=$(jq -r '.title' <<< $pr)
        url=$(jq -r '.url' <<< $pr)
        closedDate=$(date -d $closedDateString)
        if [[ $closedDate -le $7DaysAgo ]] ; then
            echo "$title pr was closed on $closedDate URL: $url"
        fi
    done < <(jq -c '.[]' <<<$last100prs)
done