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

RUN mkdir -p /certs

WORKDIR /opt/notebook
ENTRYPOINT /sbin/tini ; jupyter notebook --NotebookApp.token=test-secret --NotebookApp.allow_origin='*' \
           --NotebookApp.ip=0.0.0.0 --NotebookApp.port=9999 --no-browser --allow-root

