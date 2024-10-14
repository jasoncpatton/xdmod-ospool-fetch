FROM opensciencegrid/software-base:23-el9-release

RUN yum install -y rsync && \
yum clean all && \
rm -rf /var/cache/yum/

COPY 19_rsync_setup.sh /etc/osg/image-config.d/19_rsync_setup.sh
