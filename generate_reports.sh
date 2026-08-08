#!/bin/bash

DB="${1:?Error: Specify a database.}"

RALIGN_NUM="sed -E \"s/ ([-$.,0-9%]+)(\s*) \|/ \2\1 |/g\""
RALIGN_COL="sed \"s/^|--/===/\" | sed -E \"s/\|-(-+)--/| \1: /g\" | sed \"s/^===/\|--/\""

for file in sql/*.sql; do 
  name="${file#sql/}"
  name="${name%.sql}"
  if [[ ! "$name" =~ ^_ ]]; then
    cmd="sqlite3 $DB < sql/$name.sql | $RALIGN_NUM | $RALIGN_COL > md/$name.md";
    echo "$cmd";
    eval "$cmd";
  fi
done