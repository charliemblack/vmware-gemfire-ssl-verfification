package com.vmware.gemfire;

import org.apache.geode.cache.Region;
import org.apache.geode.cache.client.ClientCache;
import org.apache.geode.cache.client.ClientCacheFactory;
import org.apache.geode.cache.client.ClientRegionShortcut;

import java.net.InetAddress;
import java.net.UnknownHostException;

public class SimpleApp {
    public static void main(String[] args) throws UnknownHostException {
        System.setProperty("gemfirePropertyFile", "etc/gfsecurity-client-incorrect.properties");
        System.setProperty("gemfirePropertyFile", "etc/gfsecurity-client.properties");
        ClientCache clientCache = new ClientCacheFactory()
                .addPoolLocator(InetAddress.getLocalHost().getCanonicalHostName(), 10334)
                .create();
        Region region =  clientCache.createClientRegionFactory(ClientRegionShortcut.PROXY).create("test");
        region.put(1, "foo");
        System.out.println("region.get(1) = " + region.get(1));
    }
}
