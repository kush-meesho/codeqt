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
        maven && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /root

# Download and extract CodeQL CLI
RUN curl -L -o codeql.zip https://github.com/github/codeql-cli-binaries/releases/download/v2.21.3/codeql-linux64.zip && \
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
# Create .m2 directory and copy settings file
# RUN mkdir -p /root/.m2
# COPY java-settings.xml /root/.m2/settings.xml


