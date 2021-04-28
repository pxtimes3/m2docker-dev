#!/bin/bash

#set -x

cd /var/www/html/mamoco.se/magento && \
echo "Setting owner to www-data:www-data" && \
chown -R www-data:www-data . && \
echo "Setting files to 664" && \
find . -type f -exec chmod 664 {} \; && \
echo "Setting directories to 774" && \
find . -type d -exec chmod 774 {} \; && \
chmod 660 ./app/etc/env.php && \
chown root:root perms.sh && \
chmod 700 ./perms.sh