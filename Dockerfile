FROM --platform=linux/amd64 golang:1.21-bookworm AS builder

ARG GH_TOKEN

ADD . /src
WORKDIR /src

# Set up git for private repos
RUN git config --global url."https://${GH_TOKEN}@github.com".insteadOf "https://github.com"
ENV GOPRIVATE="github.com/allora-network/"
RUN make install

#==============================================================

FROM debian:bookworm-slim as execution

ENV DEBIAN_FRONTEND=noninteractive \
    USERNAME=appuser \
    APP_PATH=/data

#* curl jq - required for readyness probe and to download genesis
RUN apt update && \
    apt -y dist-upgrade && \
    apt install -y --no-install-recommends \
        curl jq \
        tzdata \
        ca-certificates && \
    echo "deb http://deb.debian.org/debian testing main" >> /etc/apt/sources.list && \
    apt update && \
    apt install -y --no-install-recommends -t testing \
      zlib1g \
      libgnutls30 \
      perl-base && \
    rm -rf /var/cache/apt/*

COPY --from=builder /go/bin/* /usr/local/bin/
COPY scripts/init.sh /init.sh

RUN groupadd -g 1001 ${USERNAME} \
    && useradd -m -d ${APP_PATH} -u 1001 -g 1001 ${USERNAME}

EXPOSE 26656 26657
VOLUME ${APP_PATH}
WORKDIR ${APP_PATH}

USER ${USERNAME}

ENTRYPOINT ["allorad"]