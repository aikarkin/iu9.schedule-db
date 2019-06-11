#!/bin/bash
docker run --rm -p 5432:5432 -v /home/alex/dev/src/iu9/postgres/:/var/lib/postgresql/pgdata  --name scheduledb karkinai/schedule-db
