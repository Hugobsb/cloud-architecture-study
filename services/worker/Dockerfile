FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY src ./src

RUN chgrp -R 0 /app \
  && chmod -R g=u /app

CMD ["npm", "start"]
