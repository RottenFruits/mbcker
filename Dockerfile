FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

#set up timezone
#https://sleepless-se.net/2018/07/31/docker-build-tzdata-ubuntu/
RUN DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y tzdata
# timezone setting
ENV TZ=Asia/Tokyo

RUN apt-get update && \
    apt-get install -y --no-install-recommends wget sudo language-pack-ja fonts-ipafont fonts-ipaexfont libboost-dev git-lfs maven nkf postgresql git

RUN sudo apt install -y --no-install-recommends  python python-psycopg2

COPY src/mbslave/ /mbslave
COPY src/mbslave.conf /mbslave
COPY src/mbdump-derived.tar.bz2 /mbslave
COPY src/mbdump.tar.bz2 /mbslave

#postgresql
USER postgres
RUN /etc/init.d/postgresql start &&\
    psql --command "CREATE USER musicbrainz WITH SUPERUSER PASSWORD 'pass';" &&\
    createdb -l C -E UTF-8 -T template0 -O musicbrainz musicbrainz &&\
    psql musicbrainz -c 'CREATE EXTENSION cube;' &&\
    psql musicbrainz -c 'CREATE EXTENSION earthdistance;' 

#Access setting
RUN sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/10/main/postgresql.conf &&\
    sed -i "s/md5/trust/" /etc/postgresql/10/main/pg_hba.conf &&\
    sed -i "s/peer/trust/" /etc/postgresql/10/main/pg_hba.conf &&\
    sed -i "$ a host all all 0.0.0.0/0 trust" /etc/postgresql/10/main/pg_hba.conf

#Prepare empty schemas for the MusicBrainz database and create the table structure
USER root
WORKDIR /mbslave/
RUN /etc/init.d/postgresql start &&\
    echo 'CREATE SCHEMA musicbrainz;' | ./mbslave-psql.py -S &&\
    echo 'CREATE SCHEMA statistics;' | ./mbslave-psql.py -S &&\
    echo 'CREATE SCHEMA cover_art_archive;' | ./mbslave-psql.py -S &&\
    echo 'CREATE SCHEMA wikidocs;' | ./mbslave-psql.py -S &&\
    echo 'CREATE SCHEMA documentation;' | ./mbslave-psql.py -S &&\
    ./mbslave-remap-schema.py <sql/CreateTables.sql | ./mbslave-psql.py &&\
    ./mbslave-remap-schema.py <sql/statistics/CreateTables.sql | ./mbslave-psql.py &&\
    ./mbslave-remap-schema.py <sql/caa/CreateTables.sql | ./mbslave-psql.py &&\
    ./mbslave-remap-schema.py <sql/wikidocs/CreateTables.sql | ./mbslave-psql.py &&\
    ./mbslave-remap-schema.py <sql/documentation/CreateTables.sql | ./mbslave-psql.py

#Data import
RUN /etc/init.d/postgresql start &&\
    ./mbslave-import.py mbdump.tar.bz2 mbdump-derived.tar.bz2

#Setup primary keys, indexes and views
RUN /etc/init.d/postgresql start &&\
    ./mbslave-remap-schema.py <sql/CreatePrimaryKeys.sql | ./mbslave-psql.py &&\ 
    ./mbslave-remap-schema.py <sql/statistics/CreatePrimaryKeys.sql | ./mbslave-psql.py &&\
    ./mbslave-remap-schema.py <sql/caa/CreatePrimaryKeys.sql | ./mbslave-psql.py &&\
    ./mbslave-remap-schema.py <sql/wikidocs/CreatePrimaryKeys.sql | ./mbslave-psql.py &&\
    ./mbslave-remap-schema.py <sql/documentation/CreatePrimaryKeys.sql | ./mbslave-psql.py &&\
    ./mbslave-remap-schema.py <sql/CreateIndexes.sql | grep -v musicbrainz_collate | ./mbslave-psql.py &&\
    ./mbslave-remap-schema.py <sql/CreateSlaveIndexes.sql | ./mbslave-psql.py &&\
    ./mbslave-remap-schema.py <sql/statistics/CreateIndexes.sql | ./mbslave-psql.py &&\
    ./mbslave-remap-schema.py <sql/caa/CreateIndexes.sql | ./mbslave-psql.py &&\
    ./mbslave-remap-schema.py <sql/CreateViews.sql | ./mbslave-psql.py &&\
    ./mbslave-remap-schema.py <sql/CreateFunctions.sql | ./mbslave-psql.py

EXPOSE 5432