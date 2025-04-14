#!/usr/bin/env bash

jq '.test'
jq --indent test ".test | map(.test)"
jq --indent -n <<EOF
".test"
EOF

echo "$1"
