FROM openjdk:17-slim

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

# Download and install sonar-scanner
ENV SONAR_SCANNER_VERSION=5.0.1.3006
RUN curl -sLo sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip && \
    unzip sonar-scanner.zip -d /opt && \
    ln -s /opt/sonar-scanner-${SONAR_SCANNER_VERSION} /opt/sonar-scanner && \
    rm sonar-scanner.zip

ENV PATH="/opt/sonar-scanner/bin:${PATH}"

# Add entrypoint script
COPY entrypoint.sh /root/entrypoint.sh
RUN chmod +x /root/entrypoint.sh

ENTRYPOINT ["/root/entrypoint.sh"]
