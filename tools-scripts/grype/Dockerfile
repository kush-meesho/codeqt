FROM ubuntu:22.04

# Install curl and other dependencies
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

# Install Grype
RUN curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin



COPY entrypoint.sh /root/entrypoint.sh
RUN chmod +x /root/entrypoint.sh
