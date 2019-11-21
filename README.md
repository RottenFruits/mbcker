# mbcker

This repository is dockerimage involve musicbrainz database.

## How to install

### File download
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

### DB

- start

```shell
/etc/init.d/postgresql start
```

- login

```shell
psql -h localhost -p 5432 -U musicbrainz
```