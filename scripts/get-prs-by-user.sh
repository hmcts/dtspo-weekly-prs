#!/usr/bin/env bash
token=$1

gh auth login --with-token ${token}
repos=$(gh search prs  --owner hmcts --author app/renovate --state=open  --sort=created --json repository -L 300 | jq -r '. | unique_by(.repository.name)' | jq -r '.[].repository.name')
respo+=($(gh search prs "[updatecli]" --owner hmcts  --state=open  --sort=created --json repository -L 300 | jq -r '. | unique_by(.repository.name)' | jq -r '.[].repository.name'))
ghusers=('endakelly' 'JusticeCarl' 'louisehuyton' 'Tyler-35' 'cpareek' 'JordanHoey96')
for ghuser in ${ghusers[@]}
do
    echo $ghuser
    for repo in  ${repos[@]}
    do  
       gh pr list --author app/renovate  --state open --repo hmcts/${repo}  --json reviewRequests,url | jq -r --arg ghuser "$ghuser" '.[] |select(.reviewRequests[].login==$ghuser) | .url '
       gh pr list --search "[updatecli]" --state open --repo hmcts/${repo}  --json reviewRequests,url | jq -r --arg ghuser "$ghuser" '.[] |select(.reviewRequests[].login==$ghuser) | .url '
    done 
done