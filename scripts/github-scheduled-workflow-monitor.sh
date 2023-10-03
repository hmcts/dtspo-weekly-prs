#!/bin/bash
# This script expects the following options:

# Github Api Token
token=$1
# Repository to check 
repo=$2
# Branch name i.e. Master
branch=$3
# Workflow run this is optional if its not speified the script will check all runs in workflow
run=$4
# Github owner 
owner=hmcts

# Check if we need to intergoate a specific run or all of the runs for that workflow 
if [[ -z "${run}" ]];
then
    echo "----"
    echo "Run not defined loop through all runs in workflows"
    # no specific run specified therefore run for each workflow in the repo
    # loop through list of workflows in repo to monitor
    workflows_response=$(curl -s -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${token}" -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/repos/${owner}/${repo}/actions/workflows | jq -r '.workflows[] | [.id , .name] |@csv')
    echo "WORKFLOW RESPONSE:"
    echo ${workflows_response}
    # While loop reads in data piped to it.
    IFS=$'\t'
    while read -r w;
    do    
        echo "Working on: "$w
        # loop through the $workflows_respose and for each of the workflows find their name and id   
        while IFS=, read -r id name;
        do
            name="${name//\"}"
            workflow_status=$(curl -s -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${token}" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repos/${owner}/${repo}/actions/workflows/${id}/runs?per_page=1&branch=${branch}" | jq -r '.workflow_runs[] | [.status , .conclusion , .html_url , .run_started_at] |@csv')
            # While loop reads in data piped to it.
            echo "Workflow status is: "
            echo NAME IS: ${name}
            echo ${workflow_status}
            while IFS=, read -r workflow_status conclusion html_url run_started_at;
            do
                # clean up responses
                
                workflow_status="${workflow_status//\"}"
                if [ -z ${workflow_status} ];
                then
                    printf ":red_circle: *$repo:* <"https://github.com/${owner}/${repo}/actions/workflows/"|_*${name}*_> Did not return a workflow status \n" >> slack-message.txt 
                else
                    conclusion="${conclusion//\"}"
                    
                    echo wf_status:${workflow_status}
                    echo conclusion:${conclusion}
                    echo runstarted:${run_started_at}
                    # Write slack message dependant on status and conclusion
                    if [ "${conclusion}" = "success" ];
                    then
                        printf ":green_circle: *$repo:* <"https://github.com/${owner}/${repo}/actions/workflows/"|_*${name}*_> status is *${workflow_status}* with conclusion *${conclusion}* \n" >> slack-message.txt 
                    elif [[ "${workflow_status}" == "waiting" ]] | [[ "${workflow_status}" == "pending" ]] | [[ "${workflow_status}" == "in_progress" ]] | [[ "${workflow_status}" == "queued" ]] | [[ "${workflow_status}" == "waiting" ]]
                    then
                        printf ":yellow_circle: *$repo:* <"https://github.com/${owner}/${repo}/actions/workflows/"|_*${name}*_> status is *${workflow_status}* with conclusion *${conclusion}* \n" >> slack-message.txt 
                    else 
                        printf ":red_circle: *$repo:* <"https://github.com/${owner}/${repo}/actions/workflows/"|_*${name}*_> status is *${workflow_status}* with conclusion *${conclusion}* \n" >> slack-message.txt 
                    fi    
                 fi    
            done  <<< ${workflow_status}
        done <<< $w
    done <<< ${workflows_response}
else
    # A specific workflow run was specified interogate only that one and get its id
    workflows_response_id=$(curl -s -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${token}" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repos/${owner}/${repo}/actions/workflows" | jq -r --arg TEST "$run" '[.workflows[]]| map(select(.name==$TEST))| [.[].id , .[].name] |@csv')
    echo ${workflows_response_id}
     # While loop reads in data piped to it.
     while IFS=, read -r id name;
        do
            
            name="${name//\"}"
            echo "id is: " $id "name is: "$name "owner:" $owner "repo " $repo "branch" $branch
            # Get the last response for that workflow id and specified branch and store status and conclusion
            workflow_status=$(curl -s -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${token}" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repos/${owner}/${repo}/actions/workflows/${id}/runs?per_page=1&branch=$branch" | jq -r '.workflow_runs[] | [.status , .conclusion , .html_url , .run_started_at] |@csv')
            # Read stored response and split status and conclusion then 
            # While loop reads in data piped to it.
            while IFS=, read -r workflow_status conclusion html_url run_started_at;
            do
                # clean up responses
                workflow_status="${workflow_status//\"}"
                echo wf_status:${workflow_status}
                if [ -z ${workflow_status} ];
                then
                    printf "> :red_circle: *$repo:* ${name}" >>slack-message.txt 
                else     
                    conclusion="${conclusion//\"}"
                    
                    echo conclusion:${conclusion}
                    echo runstarted:${run_started_at}
                    # Write slack message dependant on status and conclusion
                    if [ "${conclusion}" = "success" ];
                    then
                        printf ":green_circle: *$repo:* <"https://github.com/${owner}/${repo}/actions/workflows/"|_*${name}*_> status is *${workflow_status}* with conclusion *${conclusion}* \n" >> slack-message.txt 
                    elif [[ "${workflow_status}" == "waiting" ]] | [[ "${workflow_status}" == "pending" ]] | [[ "${workflow_status}" == "in_progress" ]] | [[ "${workflow_status}" == "queued" ]] | [[ "${workflow_status}" == "waiting" ]]
                    then
                        printf ":yellow_circle: *$repo:* <"https://github.com/${owner}/${repo}/actions/workflows/"|_*${name}*_> status is *${workflow_status}* with conclusion *${conclusion}* \n" >> slack-message.txt 
                    else 
                       printf ":red_circle: *$repo:* <"https://github.com/${owner}/${repo}/actions/workflows/"|_*${name}*_> status is *${workflow_status}* with conclusion *${conclusion}* \n" >> slack-message.txt 
                    fi    
                fi
            done  <<< ${workflow_status}
        done <<< ${workflows_response_id}
fi
