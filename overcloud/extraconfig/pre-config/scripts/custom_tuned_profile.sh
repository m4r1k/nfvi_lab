#!/bin/bash

mkdir -p /etc/tuned/${_CUSTOM_TUNED_PROFILE_NAME_} || true
chown -R root:root /etc/tuned/${_CUSTOM_TUNED_PROFILE_NAME_}
chmod 0755 /etc/tuned/${_CUSTOM_TUNED_PROFILE_NAME_}

cat > /etc/tuned/${_CUSTOM_TUNED_PROFILE_NAME_}/tuned.conf << EOF
${_CUSTOM_TUNED_PROFILE_CONTENT_}
EOF
chown -R root:root /etc/tuned/${_CUSTOM_TUNED_PROFILE_NAME_}/tuned.conf
chmod 0644 /etc/tuned/${_CUSTOM_TUNED_PROFILE_NAME_}/tuned.conf

exit 0
