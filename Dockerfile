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

EXPOSE 5432