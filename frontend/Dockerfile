# Build stage
FROM node:18-alpine as build

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies with optimizations
# Prefer npm ci when lockfile exists; if it's out-of-sync, fall back to npm install
RUN if [ -f package-lock.json ]; then \
      npm ci --no-audit --no-fund --prefer-offline --progress=false || \
      npm install --no-audit --no-fund --prefer-offline --progress=false; \
    else \
      npm install --no-audit --no-fund --prefer-offline --progress=false; \
    fi

# Copy source code and build
COPY . .
RUN npm run build

# Production stage with nginx
FROM nginx:alpine

# Copy built app from build stage
COPY --from=build /app/build /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Make nginx directories writable by root group (gid 0) so arbitrary UID can run
RUN chgrp -R 0 /usr/share/nginx/html /var/cache/nginx /var/log/nginx /etc/nginx/conf.d /var/run \
  && chmod -R g+rwX /usr/share/nginx/html /var/cache/nginx /var/log/nginx /etc/nginx/conf.d /var/run

# Expose port
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
