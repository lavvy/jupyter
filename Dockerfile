FROM alpine:3.8

LABEL maintainer "janikarh@gmail.com"

ENV LANGUAGE=C.UTF-8 LC_ALL=C.UTF-8 LANG=C.UTF-8

RUN echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
	&& apk update && apk upgrade \
	&& apk add --no-cache tini python3 libstdc++ openblas freetype wget ca-certificates \
	&& python3 -m ensurepip && rm -r /usr/lib/python*/ensurepip \
	&& pip3 install --upgrade pip setuptools \
	&& apk add --no-cache --virtual .build-deps@testing python3-dev make cmake clang clang-dev g++ \
           linux-headers libtbb libtbb-dev openblas-dev freetype-dev libxml2-dev libxslt-dev nano \
	&& export CC=/usr/bin/clang CXX=/usr/bin/clang++ \
	&& ln -s /usr/include/locale.h /usr/include/xlocale.h \
	&& mkdir -p /opt/tmp && cd /opt/tmp \
	&& pip3 install --no-cache-dir jupyter ipywidgets numpy pandas xlrd lxml matplotlib seaborn \
                pandas-highcharts ipysankeywidget calmap requests beautifulsoup4 minio sqlalchemy jupyterlab \
	&& jupyter nbextension enable --py widgetsnbextension \
	&& jupyter nbextension enable --py ipysankeywidget \
	&& echo "c.NotebookApp.token = ''" > /root/.jupyter/jupyter_notebook_config.py \
	&& cd /opt && rm -r /opt/tmp && mkdir -p /opt/notebook \
	&& unset CC CXX \
	&& apk del .build-deps \
	&& rm -r /root/.cache \
	&& find /usr/lib/python3.6/ -type d -name tests -depth -exec rm -rf {} \; \
	&& find /usr/lib/python3.6/ -type d -name test -depth -exec rm -rf {} \; \
	&& find /usr/lib/python3.6/ -name __pycache__ -depth -exec rm -rf {} \;

RUN echo -e "\n\
@edgemain http://nl.alpinelinux.org/alpine/edge/main\n\
@edgecomm http://nl.alpinelinux.org/alpine/edge/community\n\
@edgetest http://nl.alpinelinux.org/alpine/edge/testing"\
  >> /etc/apk/repositories

RUN apk update && apk upgrade && apk --no-cache add \
  bash \
  build-base \
  ca-certificates \
  clang-dev \
  clang \
  cmake \
  coreutils \
  curl  
RUN apk --no-cache add freetype-dev \
  ffmpeg-dev \
  ffmpeg-libs \
  gcc \
  g++ \
  git \
  gettext \
  lcms2-dev \
  libavc1394-dev \
  libc-dev \
  libffi-dev \
  libjpeg-turbo-dev \
  libpng-dev \
  libressl-dev \
  libtbb@edgetest \
  libtbb-dev@edgetest \
  libwebp-dev \
  linux-headers \
  make \
  musl \
  openblas \
  openblas-dev \
  openjpeg-dev \
  openssl \
  python3 \
  python3-dev \
  tiff-dev \
  unzip \
  zlib-dev

RUN ln -s /usr/bin/python3 /usr/local/bin/python && \
  ln -s /usr/bin/pip3 /usr/local/bin/pip && \
  pip install --upgrade pip

RUN ln -s /usr/include/locale.h /usr/include/xlocale.h && \
  pip install numpy

RUN mkdir -p /opt && cd /opt && \
  wget https://github.com/opencv/opencv/archive/3.2.0.zip && \
  unzip 3.2.0.zip && rm 3.2.0.zip && \
  wget https://github.com/opencv/opencv_contrib/archive/3.2.0.zip && \
  unzip 3.2.0.zip && rm 3.2.0.zip \
  && \
  cd /opt/opencv-3.2.0 && mkdir build && cd build && \
  cmake -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_C_COMPILER=/usr/bin/clang \
    -D CMAKE_CXX_COMPILER=/usr/bin/clang++ \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D INSTALL_PYTHON_EXAMPLES=OFF \
    -D INSTALL_C_EXAMPLES=OFF \
    -D WITH_FFMPEG=ON \
    -D WITH_TBB=ON \
    -D OPENCV_EXTRA_MODULES_PATH=/opt/opencv_contrib-3.2.0/modules \
    -D PYTHON_EXECUTABLE=/usr/local/bin/python \
    .. \
  && \
  make -j$(nproc) && make install && cd .. && rm -rf build \
  && \
  cp -p $(find /usr/local/lib/python3.5/site-packages -name cv2.*.so) \
   /usr/lib/python3.5/site-packages/cv2.so && \
   python -c 'import cv2; print("Python: import cv2 - SUCCESS")'
   
RUN mkdir -p /certs
RUN echo "jupyter lab --ip=0.0.0.0 --port=80 --no-browser --allow-root" > /bin/lab && chmod +x /bin/lab
WORKDIR /opt/notebook
ENTRYPOINT /sbin/tini ; jupyter notebook --NotebookApp.token=test-secret --NotebookApp.allow_origin='*' \
           --NotebookApp.ip=0.0.0.0 --NotebookApp.port=999 --no-browser --allow-root
