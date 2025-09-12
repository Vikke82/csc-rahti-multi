FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies (build essentials only if needed)
RUN apt-get update && apt-get install -y \
  gcc \
  && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Make app dir group-writable (gid 0) for arbitrary UID
RUN chgrp -R 0 /app && chmod -R g+rwX /app

# Expose port
EXPOSE 5000

# Start the application with gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "3", "--timeout", "120", "app:app"]
