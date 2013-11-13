#! /bin/sh
curl -X POST -d @closed_pullrequest.raw http://localhost:3000/pull_request --header 'Content-Type: application/x-www-form-urlencoded' --header 'Accept:  */*'