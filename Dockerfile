# Use Node.js 20 as base (includes npm and yarn)
FROM node:20-bullseye

# Install Python 3.11 and pip
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3-pip \
    python3.11-venv \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json ./
COPY requirements.txt ./

# Install Node.js dependencies
RUN npm install

# Install Python dependencies
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose common ports (adjust as needed)
EXPOSE 3000 8000

# Default command (override in docker-compose.yml or when running)
CMD ["npm", "start"]
