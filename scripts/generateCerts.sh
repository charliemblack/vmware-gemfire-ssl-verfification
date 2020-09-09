#!/bin/bash

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


mkdir -p ${APP_HOME}/certs
cd   ${APP_HOME}/certs

create_certs(){

  cd ${APP_HOME}/certs

  export local_host_name=${2}
  echo "subjectAltName = DNS:${2},ip:${3}" > ${1}.ext

  keytool -genkey -alias testing -keystore ${1}.jks -keyalg RSA -sigalg SHA256withRSA -ext SAN=dns:${2},ip:${3} << EOF
changeit
changeit
$local_host_name
Test OU
Test OU Name
Testing City
Unit Test
US
yes
changeit
changeit
EOF


  keytool -list -v -keystore ${1}.jks -storepass changeit

  # Generate the Signing Request
  keytool -keystore ${1}.jks -certreq -alias testing -keyalg rsa  -file ${1}.csr -storepass changeit -ext SAN=dns:${2},ip:${3}



  # sign it
  openssl  x509  -req  -passin pass:changeit -CA gemfire-ca-certificate.pem.txt -CAkey gemfire-ca-key.pem.txt -in ${1}.csr -out ${1}.cer  -days 365  -CAcreateserial  -extfile ${1}.ext

  keytool -import -keystore ${1}.jks -file gemfire-ca-certificate.pem.txt -alias testtrustca -storepass changeit << EOF
y
EOF

  keytool -import -keystore ${1}.jks -file ${1}.cer -alias testing -storepass changeit

  keytool -list -v -keystore ${1}.jks -storepass changeit
}

# Create the root CA
openssl  req  -passout pass:changeit -new  -x509  -keyout  gemfire-ca-key.pem.txt -out  gemfire-ca-certificate.pem.txt  -days  365 << EOF
changeit
changeit
US
CA
CA Test
The Testing CA
Tester CA
localhost
ca@foo.bar
EOF

create_certs gemfire_correct `hostname` `ifconfig -l | xargs -n1 ipconfig getifaddr`
create_certs gemfire_incorrect `hostname`-not 192.168.222.222


cd "$SAVED" >&-
