#!/bin/bash

RSYNC_KEYS_CONFIG_DIR=${RSYNC_KEYS_CONFIG_DIR:-/mnt/ssh-keys-config}

mode="$1"
if [[ "$mode" != "cron" ]]; then
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
fi

pushd $RSYNC_KEYS_CONFIG_DIR
for FILE in *; do
    echo "Installing ssh key/config $FILE to /root/.ssh/$FILE"
    install -o root -g root -m 0600 $FILE /root/.ssh/$FILE
done
popd

if [[ "$mode" != "cron" ]]; then
    # Periodically re-install the ssh key
    cat >/etc/cron.d/rsync-setup.cron <<EOF
SHELL=/bin/bash
PATH=/usr/sbin:/usr/bin:/sbin:/bin
*/5 * * * * /etc/osg/image-config.d/19_rsync_setup.sh cron >>/var/log/rsync-setup.log
EOF

    # Run the rsync once per day, time in UTC
    cat >/etc/cron.d/rsync-ospool-logs.cron <<EOF
SHELL=/bin/bash
PATH=/usr/sbin:/usr/bin:/sbin:/bin
30 10 * * * rsync -ave ssh ${RSYNC_SOURCE} ${RSYNC_TARGET} >>/var/log/rsync-ospool-logs.log
EOF

    # Run the rsync now if RUN_RSYNC_NOW is defined
    if [[ "x${RUN_RSYNC_NOW}" != "x" ]]; then
        rsync -ave ssh ${RSYNC_SOURCE} ${RSYNC_TARGET} >>/var/log/rsync-ospool-logs.log
    fi
fi
