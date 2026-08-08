#!/bin/bash

DB="${1:?Error: Specify a database.}"

for file in sql/*.sql; do 
  name="${file#sql/}"
  name="${name%.sql}"
  if [[ ! "$name" =~ ^_ ]]; then
    cmd="sqlite3 $DB < sql/$name.sql | sed -E \"s/ ([-$.,0-9%]+)(\s*) \|/ \2\1 |/g\" > md/$name.md";
    echo "$cmd";
    eval "$cmd";
  fi
done