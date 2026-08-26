# Stage 1: Build the docs
FROM squidfunk/mkdocs-material:9 AS builder

WORKDIR /docs

COPY .docs .

RUN mkdocs build --strict


# Stage 2: Serve with Nginx
FROM nginx:alpine

COPY --from=builder /docs/site /usr/share/nginx/html

EXPOSE 80