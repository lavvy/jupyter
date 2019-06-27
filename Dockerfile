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

RUN echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
	&& apk update && apk upgrade \
	&& apk add --no-cache tini python3 libstdc++ openblas freetype wget ca-certificates \
	&& pip3 install --upgrade pip setuptools \
	&& apk add --no-cache --virtual .build-deps@testing python3-dev make cmake clang clang-dev g++ linux-headers libtbb libtbb-dev openblas-dev freetype-dev \
	&& export CC=/usr/bin/clang CXX=/usr/bin/clang++ \
	&& mkdir -p /opt/tmp && cd /opt/tmp \
	&& pip3 download -d /opt/tmp numpy \
	&& unzip -q numpy*.zip \
	&& cd numpy* && echo "Building numpy..." \
	&& echo -e "[ALL]\nlibrary_dirs = /usr/lib\ninclude_dirs = /usr/include\n[atlas]\natlas_libs = openblas\nlibraries = openblas\n[openblas]\nlibraries = openblas\nlibrary_dirs = /usr/lib\ninclude_dirs = /usr/include\n" > site.cfg \
	&& python3 setup.py build -j 4 install &> /dev/null && echo "Successfully installed numpy" \
	&& cd /opt/tmp \
	&& echo "Downloading opencv" && wget --quiet https://github.com/opencv/opencv/archive/4.0.1.zip \
	&& unzip -q 4.0.1.zip \
	&& cd opencv* \
	&& mkdir build && cd build && echo "Building opencv..." \
	&& cmake -D CMAKE_BUILD_TYPE=RELEASE \
		-D CMAKE_INSTALL_PREFIX=/usr \
		-D INSTALL_C_EXAMPLES=OFF \
		-D INSTALL_PYTHON_EXAMPLES=OFF \
		-D WITH_FFMPEG=NO \
		-D WITH_IPP=NO \
		-D WITH_OPENEXR=NO \
		-D WITH_WEBP=NO \
		-D WITH_TIFF=NO \
		-D WITH_JASPER=NO \
		-D BUILD_EXAMPLES=OFF \
		-D BUILD_PERF_TESTS=NO \
		-D BUILD_TESTS=NO .. \
	&& make && make install && echo "Successfully installed opencv"
	
RUN mkdir -p /certs
RUN echo "jupyter lab --ip=0.0.0.0 --port=80 --no-browser --allow-root" > /bin/lab && chmod +x /bin/lab
WORKDIR /opt/notebook
ENTRYPOINT /sbin/tini ; jupyter notebook --NotebookApp.token=test-secret --NotebookApp.allow_origin='*' \
           --NotebookApp.ip=0.0.0.0 --NotebookApp.port=999 --no-browser --allow-root
