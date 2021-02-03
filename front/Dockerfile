FROM node:14.15.4-buster
# install elm
RUN curl -L -o elm.gz https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz && \
  gunzip elm.gz && \
  chmod +x elm && \
  mv elm /usr/local/bin/
COPY . /front
WORKDIR /front
RUN npm install --only=prod
RUN make build
CMD node server.js
