#!/bin/bash
docker build -t karkinai/schedule-db:1.0.1 -t karkinai/schedule-db:latest --build-arg DB_FILL_JAR=./dbfill.jar --build-arg INIT_DIR=./init .