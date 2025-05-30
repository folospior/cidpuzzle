ARG GLEAM_VERSION=v1.10.0

FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-erlang-alpine AS builder

COPY ./shared /build/shared
COPY ./client /build/client
COPY ./server /build/server

RUN cd /build/shared && gleam deps download
RUN cd /build/client && gleam deps download
RUN cd /build/server && gleam deps download

RUN cd /build/client && gleam add --dev lustre_dev_tools && gleam run -m lustre/dev build --minify --outdir=/build/server/priv/static

RUN cd /build/server && gleam export erlang-shipment

FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-erlang-alpine

COPY --from=builder /build/server/build/erlang-shipment /app

WORKDIR /app
RUN printf '#!/bin/sh\nexec ./entrypoint.sh "$@"' > /app/start.sh
RUN chmod +x /app/start.sh

ENV PORT=8080
EXPOSE 8080

CMD ["/app/start.sh", "run"]
