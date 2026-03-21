FROM node:18-alpine

WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy source code
COPY . .

# Expose port 8080 (Common for Flux deployments)
EXPOSE 8080

# Start the application
CMD [ "npm", "start" ]
