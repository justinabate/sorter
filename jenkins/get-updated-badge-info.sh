#!/bin/bash
#
# Brief: 
#    Sets a json endpoint for use by shields.io
#
# References:
#    https://medium.com/@iffi33/adding-custom-badges-to-gitlab-a9af8e3f3569
#
# Details:
#    github readme will be able to post a badge, based on a specific json query  
#    https://img.shields.io/badge/dynamic/json.svg?label=commits&url=https://raw.githubusercontent.com/justinabate/sorter/master/jenkins/badges.json&query=commits&colorB=brightgreen
# 


commits=`git rev-list --all --count`
# latest_release_tag=$(git describe --tags `git rev-list --tags --max-count=1`)
# echo "{\"commits\":\"$commits\", \"release_tag"\:\"$latest_release_tag\"}" > badges.json
echo "{\"commits\":\"$commits\"}" > badges.json
echo "got code repository badge status"