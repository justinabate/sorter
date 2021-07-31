#!/bin/bash
#
# Brief: 
#    Sets a json endpoint for use by shields.io
#    json gets committed to https://raw.githubusercontent.com/justinabate/sorter/master/jenkins/badges.json
#
# Details:
#    github readme posts badge via shields.io, based on a query to a json key
#    https://img.shields.io/badge/dynamic/json.svg?label=commits&url=https://raw.githubusercontent.com/justinabate/sorter/master/jenkins/badges.json&query=commits&colorB=brightgreen
# 
# References:
#    https://medium.com/@iffi33/adding-custom-badges-to-gitlab-a9af8e3f3569
#

cur_dir=$(dirname -- $(readlink -fn -- "$0"))

jenkins_API_token=$(cat $cur_dir/api_token.txt)

# fetch jenkins pipeline status
pipeline_json=$(curl -sX GET http://localhost:8080/job/test_pipeline/api/json --user admin:$jenkins_API_token)
last_build=$(echo "$pipeline_json" | jq '.lastBuild .number')

# fetch last build status
build_json=$(curl -sX GET http://localhost:8080/job/test_pipeline/$last_build/api/json --user admin:$jenkins_API_token)
jenkins_build_status=$(echo "$build_json" | jq '.result')

if [ $jenkins_build_status == '"SUCCESS"' ]; then
    build="passing"
else
    build="failing"
fi


# fetch git commit status
commits=$(($(git rev-list --all --count) + 1))

# latest_release_tag=$(git describe --tags `git rev-list --tags --max-count=1`)
# echo "{\"commits\":\"$commits\", \"release_tag"\:\"$latest_release_tag\"}" > badges.json
echo "{\"build\":\"$build\", \"commits\":\"$commits\"}" > $cur_dir/badges.json
echo "set code repository badge status"
