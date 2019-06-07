FROM postgres:10.8

ARG DB_FILL_JAR
ARG INIT_DIR

ENV POSTGRES_USER=admin
ENV POSTGRES_PASSWORD=admin
ENV PGDATA=/var/lib/postgresql/pgdata
ENV LOG_DIR=/var/log/schedule/dbfill/

RUN useradd ${POSTGRES_USER}
USER ${POSTGRES_USER}
WORKDIR /home/${POSTGRES_USER}
COPY ${DB_FILL_JAR} dbfill.jar
COPY ./data/ data/

USER root
RUN mkdir -p ${LOG_DIR}
RUN mkdir -p ${PGDATA}

RUN chown ${POSTGRES_USER}:${POSTGRES_USER} dbfill.jar
RUN chown ${POSTGRES_USER}:${POSTGRES_USER} ${PGDATA}
RUN chown -R ${POSTGRES_USER}:${POSTGRES_USER} /home/${POSTGRES_USER}/data
RUN chmod 766 ${LOG_DIR}
RUN chmod 770 ${PGDATA}
RUN apt-get update -qyy
RUN apt-get install -qyy default-jre-headless

USER ${POSTGRES_USER}
ADD ${INIT_DIR} /docker-entrypoint-initdb.d/