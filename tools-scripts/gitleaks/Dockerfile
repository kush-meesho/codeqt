FROM zricethezav/gitleaks:latest

# Copy the entrypoint script
COPY entrypoint.sh /root/entrypoint.sh

# Make the script executable and ensure it has Unix line endings
RUN chmod +x /root/entrypoint.sh && \
    sed -i 's/\r$//' /root/entrypoint.sh