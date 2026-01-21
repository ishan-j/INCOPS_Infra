FROM node:18-alpine
WORKDIR /app
# Jenkins will move code into a folder named 'backend'
COPY backend/package*.json ./
RUN npm install express
RUN npm install
COPY backend/ .
EXPOSE 5000
CMD ["node", "server.js"]