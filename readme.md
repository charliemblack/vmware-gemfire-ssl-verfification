# Checking client certs

In this sample project I attempt to see what happens when we use a certificate that doesn't have the correct CN or SAN.    

This example was made to work on MAC.   

- [Running the sample](#running-the-sample)
    - [1- Generate the certs](#1-generate-the-certs)
    - [2 - Start GemFire](#2-start-gemfire)
    - [3 - Run the client](#3-run-the-client)
        - [Example Failure](#example-failure)
        - [Example Success](#example-success)
    - [Shutdown](#shutdown)

# Running the sample

### 1- Generate the certs

The certs are created with the current machine to run everything locally.   

```shell script
$ cd <project>/certs
$ ./generateCerts.sh
```

We can inspect some of the certs here we can see what the contents of the correct & incorrect cert are.    By some chance your IP is `192.168.222.222` then it technically wont be incorrect.   You can just change up the IP in the script if it is.

```shell script
$ keytool -printcertreq -file ../certs/gemfire_correct.csr
PKCS #10 Certificate Request (Version 1.0)
Subject: CN=voltron, OU=Test OU, O=Test OU Name, L=Testing City, ST=Unit Test, C=US
Format: X.509
Public Key: 2048-bit RSA key
Signature algorithm: SHA256withRSA

Extension Request:

#1: ObjectId: 2.5.29.17 Criticality=false
SubjectAlternativeName [
  DNSName: voltron
  IPAddress: 192.168.1.108
]

#2: ObjectId: 2.5.29.14 Criticality=false
SubjectKeyIdentifier [
KeyIdentifier [
0000: 73 19 BD C8 67 ED CA C6   F5 88 87 F7 89 A7 63 BF  s...g.........c.
0010: 0F FE 6C 14                                        ..l.
]
]

voltron:scripts cblack$ keytool -printcertreq -file ../certs/gemfire_incorrect.csr
PKCS #10 Certificate Request (Version 1.0)
Subject: CN=voltron-not, OU=Test OU, O=Test OU Name, L=Testing City, ST=Unit Test, C=US
Format: X.509
Public Key: 2048-bit RSA key
Signature algorithm: SHA256withRSA

Extension Request:

#1: ObjectId: 2.5.29.17 Criticality=false
SubjectAlternativeName [
  DNSName: voltron-not
  IPAddress: 192.168.222.222
]

#2: ObjectId: 2.5.29.14 Criticality=false
SubjectKeyIdentifier [
KeyIdentifier [
0000: DE 20 11 5D 9F 89 77 07   61 C7 C7 D4 27 F0 A1 7C  . .]..w.a...'...
0010: 00 12 C0 A3                                        ....
]
]
```
### 2 - Start GemFire

The scripts will start up the GemFire system with 1 locator and 2 servers.    Server 1 will connect with the correct certificates.   Server 2 will attempt to connect with incorrect certificates.

```shell script
$ cd <project>/scripts
$./startGemFire.sh
```

The interesting item to note is the `-Djdk.tls.trustNameService=true` Java option.    This tells the JVM to do some reverse DNS on the TCP/IP connection to derive the fully qualified domain name (FQDN).  I put both the FQDN and IP address in the SubjectAlternativeName so its not as important but something to remember when things aren't working 100%

### 3 - Run the client

I wasn't 100% sure on how to accomplish making one simple client to be denied or accepted.  So we need to comment out one of these lines to achive the results needed in the `SimpleApp` main.

```java
System.setProperty("gemfirePropertyFile", "etc/gfsecurity-client-incorrect.properties");
System.setProperty("gemfirePropertyFile", "etc/gfsecurity-client.properties");   
```

With `System.setProperty("gemfirePropertyFile", "etc/gfsecurity-client-incorrect.properties");` the servers will reject the connection.

With `System.setProperty("gemfirePropertyFile", "etc/gfsecurity-client.properties");` the server will accept the connection.

#### Example Failure

*Client*
```shell script
ERROR StatusLogger Log4j2 could not find a logging implementation. Please add log4j-core to the classpath. Using SimpleLogger to log to the console...
SLF4J: Failed to load class "org.slf4j.impl.StaticLoggerBinder".
SLF4J: Defaulting to no-operation (NOP) logger implementation
SLF4J: See http://www.slf4j.org/codes.html#StaticLoggerBinder for further details.
FATAL SocketCreator Problem forming SSL connection to voltron/192.168.1.108[10334].
 javax.net.ssl.SSLHandshakeException: sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
	at sun.security.ssl.Alerts.getSSLException(Alerts.java:192)
	at sun.security.ssl.SSLSocketImpl.fatal(SSLSocketImpl.java:1946)
	at sun.security.ssl.Handshaker.fatalSE(Handshaker.java:316)
	at sun.security.ssl.Handshaker.fatalSE(Handshaker.java:310)
	at sun.security.ssl.ClientHandshaker.serverCertificate(ClientHandshaker.java:1639)
	at sun.security.ssl.ClientHandshaker.processMessage(ClientHandshaker.java:223)
	at sun.security.ssl.Handshaker.processLoop(Handshaker.java:1037)
	at sun.security.ssl.Handshaker.process_record(Handshaker.java:965)
	at sun.security.ssl.SSLSocketImpl.readRecord(SSLSocketImpl.java:1064)
	at sun.security.ssl.SSLSocketImpl.performInitialHandshake(SSLSocketImpl.java:1367)
	at sun.security.ssl.SSLSocketImpl.startHandshake(SSLSocketImpl.java:1395)
	at sun.security.ssl.SSLSocketImpl.startHandshake(SSLSocketImpl.java:1379)
	at org.apache.geode.internal.net.SocketCreator.configureClientSSLSocket(SocketCreator.java:1096)
	at org.apache.geode.internal.net.SocketCreator.connect(SocketCreator.java:877)
	at org.apache.geode.internal.net.SocketCreator.connect(SocketCreator.java:839)
	at org.apache.geode.internal.net.SocketCreator.connect(SocketCreator.java:828)
	at org.apache.geode.distributed.internal.tcpserver.TcpClient.getServerVersion(TcpClient.java:290)
	at org.apache.geode.distributed.internal.tcpserver.TcpClient.requestToServer(TcpClient.java:184)
	at org.apache.geode.cache.client.internal.AutoConnectionSourceImpl.queryOneLocatorUsingConnection(AutoConnectionSourceImpl.java:202)
	at org.apache.geode.cache.client.internal.AutoConnectionSourceImpl.queryOneLocator(AutoConnectionSourceImpl.java:192)
	at org.apache.geode.cache.client.internal.AutoConnectionSourceImpl.queryLocators(AutoConnectionSourceImpl.java:274)
	at org.apache.geode.cache.client.internal.AutoConnectionSourceImpl.findServer(AutoConnectionSourceImpl.java:157)
	at org.apache.geode.cache.client.internal.ConnectionFactoryImpl.createClientToServerConnection(ConnectionFactoryImpl.java:191)
	at org.apache.geode.cache.client.internal.pooling.ConnectionManagerImpl.createPooledConnection(ConnectionManagerImpl.java:192)
	at org.apache.geode.cache.client.internal.pooling.ConnectionManagerImpl.createPooledConnection(ConnectionManagerImpl.java:186)
	at org.apache.geode.cache.client.internal.pooling.ConnectionManagerImpl.borrowConnection(ConnectionManagerImpl.java:269)
	at org.apache.geode.cache.client.internal.OpExecutorImpl.execute(OpExecutorImpl.java:125)
	at org.apache.geode.cache.client.internal.OpExecutorImpl.execute(OpExecutorImpl.java:108)
	at org.apache.geode.cache.client.internal.PoolImpl.execute(PoolImpl.java:770)
	at org.apache.geode.cache.client.internal.PutOp.execute(PutOp.java:89)
	at org.apache.geode.cache.client.internal.ServerRegionProxy.put(ServerRegionProxy.java:159)
	at org.apache.geode.internal.cache.LocalRegion.serverPut(LocalRegion.java:3028)
	at org.apache.geode.internal.cache.LocalRegion.cacheWriteBeforePut(LocalRegion.java:3145)
	at org.apache.geode.internal.cache.ProxyRegionMap.basicPut(ProxyRegionMap.java:238)
	at org.apache.geode.internal.cache.LocalRegion.virtualPut(LocalRegion.java:5572)
	at org.apache.geode.internal.cache.LocalRegionDataView.putEntry(LocalRegionDataView.java:162)
	at org.apache.geode.internal.cache.LocalRegion.basicPut(LocalRegion.java:5028)
	at org.apache.geode.internal.cache.LocalRegion.validatedPut(LocalRegion.java:1628)
	at org.apache.geode.internal.cache.LocalRegion.put(LocalRegion.java:1615)
	at org.apache.geode.internal.cache.AbstractRegion.put(AbstractRegion.java:432)
	at com.vmware.gemfire.SimpleApp.main(SimpleApp.java:19)
Caused by: sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
	at sun.security.validator.PKIXValidator.doBuild(PKIXValidator.java:397)
	at sun.security.validator.PKIXValidator.engineValidate(PKIXValidator.java:302)
	at sun.security.validator.Validator.validate(Validator.java:262)
	at sun.security.ssl.X509TrustManagerImpl.validate(X509TrustManagerImpl.java:330)
	at sun.security.ssl.X509TrustManagerImpl.checkTrusted(X509TrustManagerImpl.java:237)
	at sun.security.ssl.X509TrustManagerImpl.checkServerTrusted(X509TrustManagerImpl.java:132)
	at sun.security.ssl.ClientHandshaker.serverCertificate(ClientHandshaker.java:1621)
	... 36 more
Caused by: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
	at sun.security.provider.certpath.SunCertPathBuilder.build(SunCertPathBuilder.java:141)
	at sun.security.provider.certpath.SunCertPathBuilder.engineBuild(SunCertPathBuilder.java:126)
	at java.security.cert.CertPathBuilder.build(CertPathBuilder.java:280)
	at sun.security.validator.PKIXValidator.doBuild(PKIXValidator.java:392)
	... 42 more
FATAL SocketCreator Problem forming SSL connection to voltron/192.168.1.108[10334].
 FATAL SocketCreator Problem forming SSL connection to voltron/192.168.1.108[10334].
 javax.net.ssl.SSLHandshakeException: sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
	at sun.security.ssl.Alerts.getSSLException(Alerts.java:192)
	at sun.security.ssl.SSLSocketImpl.fatal(SSLSocketImpl.java:1946)
	at sun.security.ssl.Handshaker.fatalSE(Handshaker.java:316)
	at sun.security.ssl.Handshaker.fatalSE(Handshaker.java:310)
	at sun.security.ssl.ClientHandshaker.serverCertificate(ClientHandshaker.java:1639)
	at sun.security.ssl.ClientHandshaker.processMessage(ClientHandshaker.java:223)
	at sun.security.ssl.Handshaker.processLoop(Handshaker.java:1037)
	at sun.security.ssl.Handshaker.process_record(Handshaker.java:965)
	at sun.security.ssl.SSLSocketImpl.readRecord(SSLSocketImpl.java:1064)
	at sun.security.ssl.SSLSocketImpl.performInitialHandshake(SSLSocketImpl.java:1367)
	at sun.security.ssl.SSLSocketImpl.startHandshake(SSLSocketImpl.java:1395)
	at sun.security.ssl.SSLSocketImpl.startHandshake(SSLSocketImpl.java:1379)
	at org.apache.geode.internal.net.SocketCreator.configureClientSSLSocket(SocketCreator.java:1096)
	at org.apache.geode.internal.net.SocketCreator.connect(SocketCreator.java:877)
	at org.apache.geode.internal.net.SocketCreator.connect(SocketCreator.java:839)
	at org.apache.geode.internal.net.SocketCreator.connect(SocketCreator.java:828)
	at org.apache.geode.distributed.internal.tcpserver.TcpClient.getServerVersion(TcpClient.java:290)
	at org.apache.geode.distributed.internal.tcpserver.TcpClient.requestToServer(TcpClient.java:184)
	at org.apache.geode.cache.client.internal.AutoConnectionSourceImpl.queryOneLocatorUsingConnection(AutoConnectionSourceImpl.java:202)
	at org.apache.geode.cache.client.internal.AutoConnectionSourceImpl.queryOneLocator(AutoConnectionSourceImpl.java:192)
	at org.apache.geode.cache.client.internal.AutoConnectionSourceImpl.queryLocators(AutoConnectionSourceImpl.java:274)
	at org.apache.geode.cache.client.internal.AutoConnectionSourceImpl.access$200(AutoConnectionSourceImpl.java:63)
	at org.apache.geode.cache.client.internal.AutoConnectionSourceImpl$UpdateLocatorListTask.run2(AutoConnectionSourceImpl.java:477)
	at org.apache.geode.cache.client.internal.PoolImpl$PoolTask.run(PoolImpl.java:1303)
	at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:511)
	at java.util.concurrent.FutureTask.runAndReset(FutureTask.java:308)
	at org.apache.geode.internal.ScheduledThreadPoolExecutorWithKeepAlive$DelegatingScheduledFuture.run(ScheduledThreadPoolExecutorWithKeepAlive.java:276)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)
Caused by: sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
	at sun.security.validator.PKIXValidator.doBuild(PKIXValidator.java:397)
	at sun.security.validator.PKIXValidator.engineValidate(PKIXValidator.java:302)
	at sun.security.validator.Validator.validate(Validator.java:262)
	at sun.security.ssl.X509TrustManagerImpl.validate(X509TrustManagerImpl.java:330)
	at sun.security.ssl.X509TrustManagerImpl.checkTrusted(X509TrustManagerImpl.java:237)
	at sun.security.ssl.X509TrustManagerImpl.checkServerTrusted(X509TrustManagerImpl.java:132)
	at sun.security.ssl.ClientHandshaker.serverCertificate(ClientHandshaker.java:1621)
	... 25 more
Caused by: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
	at sun.security.provider.certpath.SunCertPathBuilder.build(SunCertPathBuilder.java:141)
	at sun.security.provider.certpath.SunCertPathBuilder.engineBuild(SunCertPathBuilder.java:126)
	at java.security.cert.CertPathBuilder.build(CertPathBuilder.java:280)
	at sun.security.validator.PKIXValidator.doBuild(PKIXValidator.java:392)
	... 31 more
Exception in thread "main" javax.net.ssl.SSLHandshakeException: sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
	at sun.security.ssl.Alerts.getSSLException(Alerts.java:192)
	at sun.security.ssl.SSLSocketImpl.fatal(SSLSocketImpl.java:1946)
	at sun.security.ssl.Handshaker.fatalSE(Handshaker.java:316)
	at sun.security.ssl.Handshaker.fatalSE(Handshaker.java:310)
	at sun.security.ssl.ClientHandshaker.serverCertificate(ClientHandshaker.java:1639)
	at sun.security.ssl.ClientHandshaker.processMessage(ClientHandshaker.java:223)
	at sun.security.ssl.Handshaker.processLoop(Handshaker.java:1037)
	at sun.security.ssl.Handshaker.process_record(Handshaker.java:965)
	at sun.security.ssl.SSLSocketImpl.readRecord(SSLSocketImpl.java:1064)
	at sun.security.ssl.SSLSocketImpl.performInitialHandshake(SSLSocketImpl.java:1367)
	at sun.security.ssl.SSLSocketImpl.startHandshake(SSLSocketImpl.java:1395)
	at sun.security.ssl.SSLSocketImpl.startHandshake(SSLSocketImpl.java:1379)
	at org.apache.geode.internal.net.SocketCreator.configureClientSSLSocket(SocketCreator.java:1096)
	at org.apache.geode.internal.net.SocketCreator.connect(SocketCreator.java:877)
	at org.apache.geode.internal.net.SocketCreator.connect(SocketCreator.java:839)
	at org.apache.geode.internal.net.SocketCreator.connect(SocketCreator.java:828)
	at org.apache.geode.distributed.internal.tcpserver.TcpClient.getServerVersion(TcpClient.java:290)
	at org.apache.geode.distributed.internal.tcpserver.TcpClient.requestToServer(TcpClient.java:184)
	at org.apache.geode.cache.client.internal.AutoConnectionSourceImpl.queryOneLocatorUsingConnection(AutoConnectionSourceImpl.java:202)
	at org.apache.geode.cache.client.internal.AutoConnectionSourceImpl.queryOneLocator(AutoConnectionSourceImpl.java:192)
	at org.apache.geode.cache.client.internal.AutoConnectionSourceImpl.queryLocators(AutoConnectionSourceImpl.java:274)
	at org.apache.geode.cache.client.internal.AutoConnectionSourceImpl.findServer(AutoConnectionSourceImpl.java:157)
	at org.apache.geode.cache.client.internal.ConnectionFactoryImpl.createClientToServerConnection(ConnectionFactoryImpl.java:191)
	at org.apache.geode.cache.client.internal.pooling.ConnectionManagerImpl.createPooledConnection(ConnectionManagerImpl.java:192)
	at org.apache.geode.cache.client.internal.pooling.ConnectionManagerImpl.createPooledConnection(ConnectionManagerImpl.java:186)
	at org.apache.geode.cache.client.internal.pooling.ConnectionManagerImpl.prefillConnection(ConnectionManagerImpl.java:583)
	at org.apache.geode.cache.client.internal.pooling.ConnectionManagerImpl.prefill(ConnectionManagerImpl.java:551)
	at org.apache.geode.cache.client.internal.pooling.ConnectionManagerImpl.access$200(ConnectionManagerImpl.java:70)
	at org.apache.geode.cache.client.internal.pooling.ConnectionManagerImpl$PrefillConnectionsTask.run2(ConnectionManagerImpl.java:663)
	at org.apache.geode.cache.client.internal.PoolImpl$PoolTask.run(PoolImpl.java:1303)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)
Caused by: sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
	at sun.security.validator.PKIXValidator.doBuild(PKIXValidator.java:397)
	at sun.security.validator.PKIXValidator.engineValidate(PKIXValidator.java:302)
	at sun.security.validator.Validator.validate(Validator.java:262)
	at sun.security.ssl.X509TrustManagerImpl.validate(X509TrustManagerImpl.java:330)
	at sun.security.ssl.X509TrustManagerImpl.checkTrusted(X509TrustManagerImpl.java:237)
	at sun.security.ssl.X509TrustManagerImpl.checkServerTrusted(X509TrustManagerImpl.java:132)
	at sun.security.ssl.ClientHandshaker.serverCertificate(ClientHandshaker.java:1621)
	... 28 more
Caused by: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
	at sun.security.provider.certpath.SunCertPathBuilder.build(SunCertPathBuilder.java:141)
	at sun.security.provider.certpath.SunCertPathBuilder.engineBuild(SunCertPathBuilder.java:126)
	at java.security.cert.CertPathBuilder.build(CertPathBuilder.java:280)
	at sun.security.validator.PKIXValidator.doBuild(PKIXValidator.java:392)
	... 34 more
org.apache.geode.distributed.internal.tcpserver.LocatorCancelException: Unable to form SSL connection, caused by javax.net.ssl.SSLHandshakeException: sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
	at org.apache.geode.distributed.internal.tcpserver.TcpClient.getServerVersion(TcpClient.java:293)
	at org.apache.geode.distributed.internal.tcpserver.TcpClient.requestToServer(TcpClient.java:184)
	at org.apache.geode.cache.client.internal.AutoConnectionSourceImpl.queryOneLocatorUsingConnection(AutoConnectionSourceImpl.java:202)
	at org.apache.geode.cache.client.internal.AutoConnectionSourceImpl.queryOneLocator(AutoConnectionSourceImpl.java:192)
	at org.apache.geode.cache.client.internal.AutoConnectionSourceImpl.queryLocators(AutoConnectionSourceImpl.java:274)
	at org.apache.geode.cache.client.internal.AutoConnectionSourceImpl.findServer(AutoConnectionSourceImpl.java:157)
	at org.apache.geode.cache.client.internal.ConnectionFactoryImpl.createClientToServerConnection(ConnectionFactoryImpl.java:191)
	at org.apache.geode.cache.client.internal.pooling.ConnectionManagerImpl.createPooledConnection(ConnectionManagerImpl.java:192)
	at org.apache.geode.cache.client.internal.pooling.ConnectionManagerImpl.createPooledConnection(ConnectionManagerImpl.java:186)
	at org.apache.geode.cache.client.internal.pooling.ConnectionManagerImpl.borrowConnection(ConnectionManagerImpl.java:269)
	at org.apache.geode.cache.client.internal.OpExecutorImpl.execute(OpExecutorImpl.java:125)
	at org.apache.geode.cache.client.internal.OpExecutorImpl.execute(OpExecutorImpl.java:108)
	at org.apache.geode.cache.client.internal.PoolImpl.execute(PoolImpl.java:770)
	at org.apache.geode.cache.client.internal.PutOp.execute(PutOp.java:89)
	at org.apache.geode.cache.client.internal.ServerRegionProxy.put(ServerRegionProxy.java:159)
	at org.apache.geode.internal.cache.LocalRegion.serverPut(LocalRegion.java:3028)
	at org.apache.geode.internal.cache.LocalRegion.cacheWriteBeforePut(LocalRegion.java:3145)
	at org.apache.geode.internal.cache.ProxyRegionMap.basicPut(ProxyRegionMap.java:238)
	at org.apache.geode.internal.cache.LocalRegion.virtualPut(LocalRegion.java:5572)
	at org.apache.geode.internal.cache.LocalRegionDataView.putEntry(LocalRegionDataView.java:162)
	at org.apache.geode.internal.cache.LocalRegion.basicPut(LocalRegion.java:5028)
	at org.apache.geode.internal.cache.LocalRegion.validatedPut(LocalRegion.java:1628)
	at org.apache.geode.internal.cache.LocalRegion.put(LocalRegion.java:1615)
	at org.apache.geode.internal.cache.AbstractRegion.put(AbstractRegion.java:432)
	at com.vmware.gemfire.SimpleApp.main(SimpleApp.java:19)
Caused by: javax.net.ssl.SSLHandshakeException: sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
	at sun.security.ssl.Alerts.getSSLException(Alerts.java:192)
	at sun.security.ssl.SSLSocketImpl.fatal(SSLSocketImpl.java:1946)
	at sun.security.ssl.Handshaker.fatalSE(Handshaker.java:316)
	at sun.security.ssl.Handshaker.fatalSE(Handshaker.java:310)
	at sun.security.ssl.ClientHandshaker.serverCertificate(ClientHandshaker.java:1639)
	at sun.security.ssl.ClientHandshaker.processMessage(ClientHandshaker.java:223)
	at sun.security.ssl.Handshaker.processLoop(Handshaker.java:1037)
	at sun.security.ssl.Handshaker.process_record(Handshaker.java:965)
	at sun.security.ssl.SSLSocketImpl.readRecord(SSLSocketImpl.java:1064)
	at sun.security.ssl.SSLSocketImpl.performInitialHandshake(SSLSocketImpl.java:1367)
	at sun.security.ssl.SSLSocketImpl.startHandshake(SSLSocketImpl.java:1395)
	at sun.security.ssl.SSLSocketImpl.startHandshake(SSLSocketImpl.java:1379)
	at org.apache.geode.internal.net.SocketCreator.configureClientSSLSocket(SocketCreator.java:1096)
	at org.apache.geode.internal.net.SocketCreator.connect(SocketCreator.java:877)
	at org.apache.geode.internal.net.SocketCreator.connect(SocketCreator.java:839)
	at org.apache.geode.internal.net.SocketCreator.connect(SocketCreator.java:828)
	at org.apache.geode.distributed.internal.tcpserver.TcpClient.getServerVersion(TcpClient.java:290)
	... 24 more
Caused by: sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
	at sun.security.validator.PKIXValidator.doBuild(PKIXValidator.java:397)
	at sun.security.validator.PKIXValidator.engineValidate(PKIXValidator.java:302)
	at sun.security.validator.Validator.validate(Validator.java:262)
	at sun.security.ssl.X509TrustManagerImpl.validate(X509TrustManagerImpl.java:330)
	at sun.security.ssl.X509TrustManagerImpl.checkTrusted(X509TrustManagerImpl.java:237)
	at sun.security.ssl.X509TrustManagerImpl.checkServerTrusted(X509TrustManagerImpl.java:132)
	at sun.security.ssl.ClientHandshaker.serverCertificate(ClientHandshaker.java:1621)
	... 36 more
Caused by: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
	at sun.security.provider.certpath.SunCertPathBuilder.build(SunCertPathBuilder.java:141)
	at sun.security.provider.certpath.SunCertPathBuilder.engineBuild(SunCertPathBuilder.java:126)
	at java.security.cert.CertPathBuilder.build(CertPathBuilder.java:280)
	at sun.security.validator.PKIXValidator.doBuild(PKIXValidator.java:392)
	... 42 more
```
*Server*
````shell script
[info 2020/09/09 16:00:20.169 PDT <locator request thread 5> tid=0x58] Exception in processing request from 192.168.1.108
javax.net.ssl.SSLHandshakeException: Received fatal alert: certificate_unknown
	at sun.security.ssl.Alerts.getSSLException(Alerts.java:192)
	at sun.security.ssl.Alerts.getSSLException(Alerts.java:154)
	at sun.security.ssl.SSLSocketImpl.recvAlert(SSLSocketImpl.java:2020)
	at sun.security.ssl.SSLSocketImpl.readRecord(SSLSocketImpl.java:1127)
	at sun.security.ssl.SSLSocketImpl.performInitialHandshake(SSLSocketImpl.java:1367)
	at sun.security.ssl.SSLSocketImpl.startHandshake(SSLSocketImpl.java:1395)
	at sun.security.ssl.SSLSocketImpl.startHandshake(SSLSocketImpl.java:1379)
	at org.apache.geode.internal.net.SocketCreator.handshakeIfSocketIsSSL(SocketCreator.java:1013)
	at org.apache.geode.distributed.internal.tcpserver.TcpServer.lambda$processRequest$0(TcpServer.java:355)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)
````
#### Example Success
There isn't much output from the `SimpleApp` but here it is:

```shell script
ERROR StatusLogger Log4j2 could not find a logging implementation. Please add log4j-core to the classpath. Using SimpleLogger to log to the console...
SLF4J: Failed to load class "org.slf4j.impl.StaticLoggerBinder".
SLF4J: Defaulting to no-operation (NOP) logger implementation
SLF4J: See http://www.slf4j.org/codes.html#StaticLoggerBinder for further details.
region.get(1) = foo

```
### Shutdown

Then to shutdown the GemFire distributed system run the following command:

```shell script
$ cd <project>/scripts
$ ./shutdownGemFire.sh
```
