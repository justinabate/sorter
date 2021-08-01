#!/bin/sh

# Brief
#    This curl triggers jenkins to run
#
# Details
#    Ideally, this action will be scripted into the .git/hooks/
#
# References:
#    https://githooks.com/
#

cur_dir=$(dirname -- $(readlink -fn -- "$0"))

jenkins_API_token=$(cat $cur_dir/api_token.txt)

curl -X POST "admin:$jenkins_API_token@localhost:8080/job/test_pipeline/build"
