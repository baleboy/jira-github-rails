#! /bin/sh
curl -X POST -d @open-pr.txt http://localhost:3000/pull_request --header 'Content-Type: application/x-www-form-urlencoded' --header 'Accept:  */*'