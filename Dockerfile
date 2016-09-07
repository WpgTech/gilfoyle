FROM node:4
RUN mkdir -p /app
EXPOSE 8080
ADD . /app
WORKDIR /app
CMD ["/app/bin/hubot"]
