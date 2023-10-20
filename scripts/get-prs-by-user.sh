#!/usr/bin/env bash
token=$1

gh auth login --with-token ${token}
repos=$(gh search prs  --owner hmcts --author app/renovate --state=open  --sort=created --json repository -L 300 | jq -r '. | unique_by(.repository.name)' | jq -r '.[].repository.name')
respo+=($(gh search prs "[updatecli]" --owner hmcts  --state=open  --sort=created --json repository -L 300 | jq -r '. | unique_by(.repository.name)' | jq -r '.[].repository.name'))

#ghusers=$(gh api -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" /orgs/HMCTS/teams/platops-blue/members | jq -r '.[].login')
ghusers=('JordanHoey96')

for ghuser in ${ghusers[@]}
do
    echo $ghuser
    for repo in  ${repos[@]}
    do  
       gh pr list --author app/renovate  --state open --repo hmcts/${repo}  --json reviewRequests,url,title | jq -r --arg ghuser "$ghuser" '.[] |select(.reviewRequests[].login==$ghuser) | .url | .title'
       gh pr list --search "[updatecli]" --state open --repo hmcts/${repo}  --json reviewRequests,url,title | jq -r --arg ghuser "$ghuser" '.[] |select(.reviewRequests[].login==$ghuser) | .url | .title'
    done 
done