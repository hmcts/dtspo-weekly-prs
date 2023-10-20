#!/usr/bin/env bash
token=$1

gh auth login --with-token ${token}

#ghusers=$(gh api -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" /orgs/HMCTS/teams/platops-blue/members | jq -r '.[].login')
ghusers=('JordanHoey96')

for ghuser in ${ghusers[@]}
do
    echo $ghuser
    gh search prs  --owner hmcts --author app/renovate --state=open  --sort=created --review-requested $ghuser --json url | jq '.[].url'
done