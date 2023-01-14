ARG NGINX_VERSION=1.22.1
ARG NGINX_RTMP_VERSION=1.2.2
ARG S3FS_VERSION=v1.91
# ARG FFMPEG_VERSION=5.1.2

# # Build the FFmpeg-build image.
# FROM alpine:3.8 as build-ffmpeg
# ARG FFMPEG_VERSION
# ARG PREFIX=/usr/local
# ARG MAKEFLAGS="-j4"

# # FFmpeg build dependencies.
# RUN apk add --update \
#   build-base \
#   coreutils \
#   freetype-dev \
#   lame-dev \
#   libogg-dev \
#   libass \
#   libass-dev \
#   libvpx-dev \
#   libvorbis-dev \
#   libwebp-dev \
#   libtheora-dev \
#   opus-dev \
#   pkgconf \
#   pkgconfig \
#   rtmpdump-dev \
#   wget \
#   x264-dev \
#   x265-dev \
#   yasm


# # Get FFmpeg source.
# RUN cd /tmp/ && \
#   wget http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz && \
#   tar zxf ffmpeg-${FFMPEG_VERSION}.tar.gz && rm ffmpeg-${FFMPEG_VERSION}.tar.gz

# # Compile ffmpeg.
# RUN cd /tmp/ffmpeg-${FFMPEG_VERSION} && \
#   ./configure \
#   --pkg-config-flags="--static" \
#   --prefix=${PREFIX} \
#   --enable-libx264 \
#   --enable-gpl \
#   --enable-version3 \
#   --enable-nonfree  \
#   --enable-librtmp \
#   --enable-libfreetype \
#   --disable-debug \
#   --disable-ffplay \
#   --disable-doc \
#   --extra-libs="-lpthread -lm" && \
#   make && make install && make distclean

# # Cleanup.
# RUN rm -rf /var/cache/* /tmp/*

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
  wget https://github.com/arut/nginx-rtmp-module/archive/refs/tags/v${NGINX_RTMP_VERSION}.tar.gz -O nginx-rtmp-module-${NGINX_RTMP_VERSION}.tar.gz && \
  tar zxf nginx-rtmp-module-${NGINX_RTMP_VERSION}.tar.gz && rm nginx-rtmp-module-${NGINX_RTMP_VERSION}.tar.gz

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
# COPY --from=build-ffmpeg /usr/local /usr/local

# Add NGINX path, config and static files.
ENV PATH "${PATH}:/usr/local/nginx/sbin"
ADD nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /opt/data/hls

# # Add S3FS
RUN apk --update add --virtual build-dependencies \
        ffmpeg build-base alpine-sdk \
        fuse fuse-dev \
        automake autoconf git \
        libressl-dev  \
        curl-dev libxml2-dev  \
        ca-certificates 
        

RUN git clone https://github.com/s3fs-fuse/s3fs-fuse.git; \
   cd s3fs-fuse; \
   git checkout tags/${S3FS_VERSION}; \
   ./autogen.sh; \
   ./configure --prefix=/usr; \
   make; \
   make install; \
   rm -rf /var/cache/apk/*;

  
ADD fuse.conf /etc/fuse.conf

ADD entrypoint.sh /
RUN chmod +x /entrypoint.sh

EXPOSE 1935

CMD ["/entrypoint.sh"]
