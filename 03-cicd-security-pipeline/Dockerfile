# Sample Dockerfile for security scanning demonstration
# This includes both good and bad practices for educational purposes

FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements first (good practice - layer caching)
COPY sample-app/requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY sample-app/ .

# Create non-root user (security best practice)
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8080/health')" || exit 1

# Run application
CMD ["python", "app.py"]
