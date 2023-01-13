ARG NGINX_VERSION=1.22.1
ARG NGINX_RTMP_VERSION=1.1.7.10
ARG S3FS_VERSION=v1.85

#############################
#Build the NGINX-build image.
FROM alpine:3.17 as build-nginx
ARG NGINX_VERSION
ARG NGINX_RTMP_VERSION

# Build dependencies.
RUN apk add --update --no-cache \
  build-base \
#   ca-certificates \
#   curl \
  gcc \
  libc-dev \
  libgcc \
  linux-headers \
  make \
#   musl-dev \
  openssl \
  openssl-dev \
  pcre \
  pcre-dev \
  pkgconf \
  pkgconfig \
  zlib-dev

# Get nginx source.
RUN cd /tmp && \
  wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
  tar zxf nginx-${NGINX_VERSION}.tar.gz && \
  rm nginx-${NGINX_VERSION}.tar.gz

# Get nginx-rtmp module.
RUN cd /tmp && \
  wget https://github.com/sergey-dryabzhinsky/nginx-rtmp-module/archive/refs/tags/v${NGINX_RTMP_VERSION}.tar.gz && \
  tar zxf v${NGINX_RTMP_VERSION}.tar.gz && rm v${NGINX_RTMP_VERSION}.tar.gz

# Compile nginx with nginx-rtmp module.
RUN cd /tmp/nginx-${NGINX_VERSION} && \
  ./configure \
  --prefix=/usr/local/nginx \
  --add-module=/tmp/nginx-rtmp-module-${NGINX_RTMP_VERSION} \
  --conf-path=/etc/nginx/nginx.conf \
  --with-threads \
  --with-file-aio \
  --with-debug && \
  cd /tmp/nginx-${NGINX_VERSION} && make && make install

# ###############################

##########################
# Build the release image.
FROM alpine:3.17
LABEL MAINTAINER Andrey Zhvakin <barmaglot92@gmail.com>

COPY --from=build-nginx /usr/local/nginx /usr/local/nginx

# Add NGINX path, config and static files.
ENV PATH "${PATH}:/usr/local/nginx/sbin"
ADD nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /opt/data/hls

# # Add S3FS
RUN apk add --update --no-cache ffmpeg fuse alpine-sdk automake autoconf libxml2-dev fuse-dev curl-dev git bash pcre;
RUN git clone https://github.com/s3fs-fuse/s3fs-fuse.git; \
   cd s3fs-fuse; \
   git checkout tags/${S3FS_VERSION}; \
   ./autogen.sh; \
   ./configure --prefix=/usr; \
   make; \
   make install; \
   rm -rf /var/cache/apk/*;

ADD entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 1935

CMD ["/entrypoint.sh"]
