#!/bin/sh
set -eu

PUID="${PUID:-10001}"
PGID="${PGID:-10001}"
HOME_DIR="/home/mutagen"
SSH_DIR="${HOME_DIR}/.ssh"
SSH_CONFIG_PATH="${SSH_DIR}/config"
SSH_KEY_PATH="${SSH_DIR}/id_ed25519"
SSH_PUB_PATH="${SSH_KEY_PATH}.pub"
MUTAGEN_DIR="${HOME_DIR}/.mutagen"
CURRENT_UID="$(id -u mutagen)"
CURRENT_GID="$(id -g mutagen)"

if [ "${CURRENT_GID}" != "${PGID}" ]; then
  groupmod -g "${PGID}" mutagen
fi

if [ "${CURRENT_UID}" != "${PUID}" ] || [ "${CURRENT_GID}" != "${PGID}" ]; then
  usermod -u "${PUID}" -g "${PGID}" mutagen
fi

chown mutagen:mutagen "${HOME_DIR}" "${SSH_DIR}" "${MUTAGEN_DIR}"

export SSH_DIR SSH_CONFIG_PATH SSH_KEY_PATH SSH_PUB_PATH MUTAGEN_DIR

exec gosu mutagen sh -c '
if [ ! -f "${SSH_CONFIG_PATH}" ]; then
  cat > "${SSH_CONFIG_PATH}" <<EOF
Host *
  IdentityFile /home/mutagen/.ssh/id_ed25519
  IdentitiesOnly yes
EOF
fi
if [ ! -f "${SSH_KEY_PATH}" ]; then
  ssh-keygen -t ed25519 -N "" -f "${SSH_KEY_PATH}" >/dev/null
fi
echo "Mutagen SSH public key:"
cat "${SSH_PUB_PATH}"
exec "$@"
' sh "$@"
