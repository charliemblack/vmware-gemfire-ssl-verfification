#!/bin/bash

# Attempt to set APP_HOME
# Resolve links: $0 may be a link
PRG="$0"
# Need this for relative symlinks.
while [ -h "$PRG" ] ; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
        PRG="$link"
    else
        PRG=`dirname "$PRG"`"/$link"
    fi
done
SAVED="`pwd`"
cd "`dirname \"$PRG\"`/.." >&-
APP_HOME="`pwd -P`"
cd "$SAVED" >&-




cd ${APP_HOME}
gfsh -e "connect --locator=`hostname`[10334] --security-properties-file=${APP_HOME}/etc/gfsecurity-client.properties  --ciphers=any --protocols=any" -e "shutdown --include-locators=true"
cd ${SAVED}

#rm -rf ${APP_HOME}/data/*
