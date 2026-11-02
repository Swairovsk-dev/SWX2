FROM node:24-alpine
WORKDIR /app
COPY server.mjs painel.html ./
ENV NODE_ENV=production PORT=3000 DATA_DIR=/data
# O usuário node precisa gravar o banco no volume.
RUN mkdir -p /data && chown node:node /data
VOLUME /data
EXPOSE 3000
USER node
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://127.0.0.1:3000/health || exit 1
CMD ["node", "--disable-warning=ExperimentalWarning", "server.mjs"]
