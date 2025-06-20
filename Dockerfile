ARG GLEAM_VERSION=v1.10.0

# Build stage - compile the application
FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-erlang-alpine AS builder

# Add project code
COPY ./shared /build/shared
COPY ./client /build/client
COPY ./server /build/server

# Install dependencies for all projects
RUN cd /build/shared && gleam deps download
RUN cd /build/client && gleam deps download
RUN cd /build/server && gleam deps download

# Compile the client code and output to server's static directory
RUN cd /build/client \
  && gleam add --dev lustre_dev_tools \
  && gleam run -m lustre/dev build app --minify --outdir=/build/server/priv/static

# Compile the server code
RUN cd /build/server \
  && gleam export erlang-shipment

# Runtime stage - slim image with only what's needed to run
FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-erlang-alpine

# Copy the compiled server code from the builder stage
COPY --from=builder /build/server/build/erlang-shipment /app

RUN ls /app

# Set up the entrypoint
WORKDIR /app
RUN printf '#!/bin/sh\nexec ./entrypoint.sh "$@"' > /app/start.sh && chmod +x /app/start.sh

RUN cat start.sh
# Expose the port the server will run on
EXPOSE 80

# Run the server
CMD ["./start.sh", "run"]
