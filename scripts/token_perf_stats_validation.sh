#!/bin/bash

function unscoped_token_issue {
curl \
  -s -i \
  -w "time_total: %{time_total}" \
  -H "Content-Type: application/json" -d '
  { "auth": {
      "identity": {
        "methods": ["password"],
        "password": {
          "user": {
            "name": "admin",
            "domain": { "id": "default" },
            "password": "'${OS_PASSWORD}'"
          }
        }
      }
    }
  }' \
  "${OS_AUTH_URL}/v3/auth/tokens"
}

function scoped_token_issue {
curl \
  -s -i \
  -w "time_total: %{time_total}" \
  -H "Content-Type: application/json" -d '
  { "auth": {
      "identity": {
        "methods": ["password"],
        "password": {
          "user": {
            "name": "admin",
            "domain": { "id": "default" },
            "password": "'${OS_PASSWORD}'"
          }
        }
      },
      "scope": {
        "system": {
          "all": true
        }
      }
    }
  }' \
  "${OS_AUTH_URL}/v3/auth/tokens"
}

function token_validation {
_TOKEN=$(scoped_token_issue|awk -v RS='\r' '/X-Subject-Token/ {print $2}')
curl \
  -s -i \
  -w "time_total: %{time_total}" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: ${_TOKEN}" \
  -H "X-Subject-Token: ${_TOKEN}" \
  "${OS_AUTH_URL}/v3/auth/tokens"
}
function token_validation_header {
_TOKEN=$(scoped_token_issue|awk -v RS='\r' '/X-Subject-Token/ {print $2}')
curl \
  -s -i -I \
  -w "time_total: %{time_total}" \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: ${_TOKEN}" \
  -H "X-Subject-Token: ${_TOKEN}" \
  "${OS_AUTH_URL}/v3/auth/tokens"
}

_TMP=$(mktemp --dry-run)
trap "rm -f ${_TMP}; exit 1" 2

source ~/overcloudrc

for ((i=0;i<1000;i++))
do
    token_validation|grep -E -o "(time_total.*$)"|awk '{print "Validation time:", $2}'|tee -a ${_TMP}
done

cat ${_TMP}|awk '{print $3}'|sort -n|awk '
  BEGIN {
    c = 0;
    sum = 0;
  }
  $1 ~ /^(\-)?[0-9]*(\.[0-9]*)?$/ {
    a[c++] = $1;
    sum += $1;
  }
  END {
    ave = sum / c;
    if( (c % 2) == 1 ) {
      median = a[ int(c/2) ];
    } else {
      median = ( a[c/2] + a[c/2-1] ) / 2;
    }
    format = "%-15s %-15s %-15s %-15s %-15s %s\n"
    printf format, "Summary", "Data count", "Mean datum", "Median datum", "Minimum datum", "Maximum datum";
    printf format, sum, c, ave, median, a[0], a[c-1];
  }
'

rm -f ${_TMP}
exit 0
