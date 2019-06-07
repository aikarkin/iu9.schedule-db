 #!/bin/bash
pg_ctl -o "-c listen_addresses='localhost'" -w restart


java -jar /home/${POSTGRES_USER}/dbfill.jar /home/${POSTGRES_USER}/data/config.properties