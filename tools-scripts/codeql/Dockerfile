FROM debian:bullseye-slim

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        curl \
        unzip \
        ca-certificates \
        git \
        procps \
        maven \
        golang-go && \
    rm -rf /var/lib/apt/lists/*


    WORKDIR /root
ENV GOPROXY=off
ENV GOSUMDB=off
RUN curl -L -o codeql.zip https://github.com/github/codeql-cli-binaries/releases/latest/download/codeql-linux64.zip && \
    unzip codeql.zip && \
    rm codeql.zip && \
    CODEQL_DIR=$(find . -maxdepth 1 -type d -name "codeql*") && \
    mv "$CODEQL_DIR" /usr/local/bin/codeql && \
    ls -al /usr/local/bin/codeql

# Add CodeQL to PATH
ENV PATH="/usr/local/bin/codeql:${PATH}"

# Copy and set up entrypoint script
COPY entrypoint.sh /root/entrypoint.sh
RUN chmod +x /root/entrypoint.sh



