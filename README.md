# mbcker

This repository is dockerimage involve musicbrainz database.

## How to install

### File download

- Create directory
```
mkdir src
cd src
```

- Clone [mbslave](https://github.com/lalinsky/mbslave)

```
git clone https://github.com/lalinsky/mbslave.git
```


- Download `mbdump-derived.tar.bz2` and `mbdump.tar.bz2` from http://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/ and deply `src`


- Rename and deploy `src/mbslave/mbslave.conf.default` to `src/mbslave.conf`

- Update `mbslave.conf`, token is your api token, get from https://metabrainz.org/supporters/account-type



### Docker

- docker build

``` shell
docker build . -t mbcker
docker run -it -p 5440:5432 --name mbcker mbcker /bin/bash
```

### PostgreSql
- User setting1

``` shell
/etc/init.d/postgresql start
sudo su - postgres
createuser musicbrainz -P
```
- Set password

   - You sholud enter password 2 times, set by mbslave.conf

- Create tabel
```shell
createdb -l C -E UTF-8 -T template0 -O musicbrainz musicbrainz
psql musicbrainz -c 'CREATE EXTENSION cube;'
psql musicbrainz -c 'CREATE EXTENSION earthdistance;'
exit
```

- Access setting
``` shell
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/10/main/postgresql.conf
sed -i "s/md5/trust/" /etc/postgresql/10/main/pg_hba.conf
sed -i "s/peer/trust/" /etc/postgresql/10/main/pg_hba.conf
sed -i "$ a host all all 0.0.0.0/0 trust" /etc/postgresql/10/main/pg_hba.conf
```


- Prepare empty schemas for the MusicBrainz database and create the table structure

```shell
cd mbslave/

echo 'CREATE SCHEMA musicbrainz;' | ./mbslave-psql.py -S
echo 'CREATE SCHEMA statistics;' | ./mbslave-psql.py -S
echo 'CREATE SCHEMA cover_art_archive;' | ./mbslave-psql.py -S
echo 'CREATE SCHEMA wikidocs;' | ./mbslave-psql.py -S
echo 'CREATE SCHEMA documentation;' | ./mbslave-psql.py -S

./mbslave-remap-schema.py <sql/CreateTables.sql | ./mbslave-psql.py
./mbslave-remap-schema.py <sql/statistics/CreateTables.sql | ./mbslave-psql.py
./mbslave-remap-schema.py <sql/caa/CreateTables.sql | ./mbslave-psql.py
./mbslave-remap-schema.py <sql/wikidocs/CreateTables.sql | ./mbslave-psql.py
./mbslave-remap-schema.py <sql/documentation/CreateTables.sql | ./mbslave-psql.py
```


- Data import

``` shell
./mbslave-import.py mbdump.tar.bz2 mbdump-derived.tar.bz2
```

- Setup primary keys, indexes and views

``` shell 
./mbslave-remap-schema.py <sql/CreatePrimaryKeys.sql | ./mbslave-psql.py
./mbslave-remap-schema.py <sql/statistics/CreatePrimaryKeys.sql | ./mbslave-psql.py
./mbslave-remap-schema.py <sql/caa/CreatePrimaryKeys.sql | ./mbslave-psql.py
./mbslave-remap-schema.py <sql/wikidocs/CreatePrimaryKeys.sql | ./mbslave-psql.py
./mbslave-remap-schema.py <sql/documentation/CreatePrimaryKeys.sql | ./mbslave-psql.py

./mbslave-remap-schema.py <sql/CreateIndexes.sql | grep -v musicbrainz_collate | ./mbslave-psql.py
./mbslave-remap-schema.py <sql/CreateSlaveIndexes.sql | ./mbslave-psql.py
./mbslave-remap-schema.py <sql/statistics/CreateIndexes.sql | ./mbslave-psql.py
./mbslave-remap-schema.py <sql/caa/CreateIndexes.sql | ./mbslave-psql.py

./mbslave-remap-schema.py <sql/CreateViews.sql | ./mbslave-psql.py
./mbslave-remap-schema.py <sql/CreateFunctions.sql | ./mbslave-psql.py
```


## Use

### Container and DB start

```shell
docker start mbcker
docker exec -it mbcker bin/sh
/etc/init.d/postgresql start
```

### DB login

```login
psql -h localhost -p 5432 -U musicbrainz
```