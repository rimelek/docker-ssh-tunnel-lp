#!/bin/sh

: ${TUNNEL_HOST:?cannot be empty}
: ${TUNNEL_PORT_MIN:?cannot be empty}
: ${TUNNEL_PORT_MAX:=$((TUNNEL_PORT_MIN + 100))}
# TUNNEL_REMOTES is optional

TUNNEL_PORT_DIFF=$(( (TUNNEL_PORT_MAX - TUNNEL_PORT_MIN) / 2))
TUNNEL_PORT_MIN_REMOTE=$(( 1 + TUNNEL_PORT_MIN + TUNNEL_PORT_DIFF ))

getUser() {
  local HOST_PTRN=$1
  echo $(echo ${HOST_PTRN}':@' | cut -d '@' -f 1 | cut -d ':' -f 1)
}

getHost() {
  local HOST_PTRN=$1
  local HOST_PTRN_AFTER_AT=$(echo ${HOST_PTRN}'@' | cut -d '@' -f 2)
  echo $(echo ${HOST_PTRN_AFTER_AT}':' | cut -d ':' -f 1)
}

getPort() {
  local HOST_PTRN=$1
  echo $(echo ${HOST_PTRN}':22:22' | cut -d ':' -f 3)
}

getTargetPort() {
  local HOST_PTRN=$1
  echo $(echo ${HOST_PTRN}':22' | cut -d ':' -f 2)
}

TUNNEL_HOST_USER=$(getUser ${TUNNEL_HOST})
TUNNEL_HOST_HOST=$(getHost ${TUNNEL_HOST})
TUNNEL_HOST_PORT=$(getTargetPort ${TUNNEL_HOST})

if [ "$TUNNEL_HOST_USER" != "" ] \
&& [ "$TUNNEL_HOST_HOST" = "" ]; then
  TUNNEL_HOST_HOST=${TUNNEL_HOST_USER}
  TUNNEL_HOST_USER=root
fi

COMMAND_FORWARDED_SSH='ssh -f -oStrictHostKeyChecking=no'

PORT_i=${TUNNEL_PORT_MIN}
for REMOTE in ${TUNNEL_REMOTES}; do
   REMOTE_USER=$(getUser ${REMOTE})
   REMOTE_HOST=$(getHost ${REMOTE})
   REMOTE_PORT=$(getPort ${REMOTE})

    if [ "$REMOTE_USER" != "" ] \
    && [ "$REMOTE_HOST" = "" ]; then
      REMOTE_HOST=${REMOTE_USER}
      REMOTE_USER=root
    fi

    COMMAND_FORWARDED_SSH=${COMMAND_FORWARDED_SSH}' -L '${PORT_i}':'${REMOTE_HOST}':'${REMOTE_PORT}
    PORT_i=$((PORT_i + 1))
done

COMMAND_FORWARDED_SSH=${COMMAND_FORWARDED_SSH}' '${TUNNEL_HOST_USER}'@'${TUNNEL_HOST_HOST}' -p '${TUNNEL_HOST_PORT}' -N'

echo ${COMMAND_FORWARDED_SSH}
${COMMAND_FORWARDED_SSH}

PORT_i=${TUNNEL_PORT_MIN_REMOTE}
LOOP_i=$(echo ${TUNNEL_REMOTES} | wc -w)
for REMOTE in ${TUNNEL_REMOTES}; do
   REMOTE_USER=$(getUser ${REMOTE})
   REMOTE_HOST=$(getHost ${REMOTE})
   REMOTE_TARGET_PORT=$(getTargetPort ${REMOTE})
   TUNNEL_PORT=$(( PORT_i - TUNNEL_PORT_DIFF -1 ))

    if [ "$REMOTE_USER" != "" ] \
    && [ "$REMOTE_HOST" = "" ]; then
      REMOTE_HOST=${REMOTE_USER}
      REMOTE_USER=root
    fi

    TUNNEL_BG=''
    if [ ${LOOP_i} -gt 1 ]; then
       TUNNEL_BG=' -f '
    fi
    TUNNEL_CMD='ssh '${TUNNEL_BG}' -oStrictHostKeyChecking=no -L '${PORT_i}':127.0.0.1:'${REMOTE_TARGET_PORT}' '${REMOTE_USER}'@127.0.0.01 -p '${TUNNEL_PORT}' -N'
    echo ${TUNNEL_CMD}
    ${TUNNEL_CMD}

    PORT_i=$((PORT_i + 1))
    LOOP_i=$((LOOP_i - 1))
done

