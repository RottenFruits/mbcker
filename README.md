# mbcker

This repository is dockerimage involve [musicbrainz](https://musicbrainz.org/) database.

## How to install

### Clone this repository
- Clone this repository

```
git clone https://github.com/RottenFruits/mbcker.git
cd mbcker
```


### Extra file download
- Clone [mbslave](https://github.com/lalinsky/mbslave)

```
cd src
git clone https://github.com/lalinsky/mbslave.git
```


- Download `mbdump-derived.tar.bz2` and `mbdump.tar.bz2` from http://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/ and deply `src`

### Docker

- build and run

``` shell
docker build . -t mbcker
docker run -it -p 5440:5432 --name mbcker mbcker /bin/bash
```

### DataBase

- start

```shell
/etc/init.d/postgresql start
```

- login

```shell
psql -h localhost -p 5432 -U musicbrainz
```

- use client
![p1](https://raw.githubusercontent.com/RottenFruits/mbcker/master/file/スクリーンショット%202019-11-22%2021.29.30.png "p1")