FROM owasp/dependency-check:latest

USER root


COPY entrypoint.sh /usr/share/dependency-check/bin/entrypoint.sh
RUN chmod +x /usr/share/dependency-check/bin/entrypoint.sh

USER dependencycheck