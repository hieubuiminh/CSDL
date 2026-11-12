FROM node:22-alpine

WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev

COPY --chown=node:node backend ./backend
COPY --chown=node:node public ./public
RUN mkdir -p /app/data && chown node:node /app/data

ENV NODE_ENV=production
EXPOSE 3000

USER node
CMD ["npm", "start"]

