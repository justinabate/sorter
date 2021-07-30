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

jenkins_API_token=$(cat ./api_token.txt)

curl -X POST "admin:$jenkins_API_token@localhost:8080/job/test_pipeline/build"


