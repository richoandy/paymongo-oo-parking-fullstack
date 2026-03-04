#!/bin/bash
set -e
psql -v ON_ERROR_STOP=1 --username postgres --dbname postgres <<-EOSQL
  CREATE DATABASE parking_test;
  GRANT ALL PRIVILEGES ON DATABASE parking_test TO parking_user;
EOSQL
