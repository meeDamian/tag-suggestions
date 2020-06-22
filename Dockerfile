FROM alpine:3.12

RUN apk add --no-cache git jq

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
