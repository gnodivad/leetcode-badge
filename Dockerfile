FROM haozibi/upx AS build-upx

FROM golang:1.16.0-alpine3.13 AS build-env

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories

RUN apk --no-cache add build-base git

# build
ARG BIN_NAME=leetcode-badge
WORKDIR /${BIN_NAME}
ADD go.mod .
ADD go.sum .
RUN go env -w GO111MODULE=on && go env -w GOPROXY="https://goproxy.cn,direct" && go mod download
ADD . .
RUN make build-linux

# upx
WORKDIR /data
COPY --from=build-upx /bin/upx /bin/upx
RUN cp /${BIN_NAME}/bin/${BIN_NAME} /data/main
# RUN upx -k --best --ultra-brute /data/main

FROM alpine:3.13

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories

RUN apk update && apk add tzdata \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \ 
    && echo "Asia/Shanghai" > /etc/timezone

RUN apk add --update ca-certificates && rm -rf /var/cache/apk/*

COPY --from=build-env /data/main /home/main

RUN ls -alh /home/main && /home/main help

ENTRYPOINT ["/home/main","run"]