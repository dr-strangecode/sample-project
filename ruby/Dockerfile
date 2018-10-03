FROM ruby:slim
MAINTAINER Tim Ray <tim.ray2005@gmail.com>

ENV INSTALL_PATH /app

WORKDIR ${INSTALL_PATH}

RUN apt-get update && \
    apt-get install build-essential --no-install-recommends -y

ADD . ${INSTALL_PATH}

RUN cd ${INSTALL_PATH} && \
    bundle install
