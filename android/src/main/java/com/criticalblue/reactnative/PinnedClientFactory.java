package com.criticalblue.reactnative;

import com.facebook.react.modules.network.OkHttpClientFactory;
import com.facebook.react.modules.network.OkHttpClientProvider;

import okhttp3.CertificatePinner;
import okhttp3.OkHttpClient;

public class PinnedClientFactory implements OkHttpClientFactory {
    private CertificatePinner certificatePinner;

    public PinnedClientFactory(CertificatePinner certificatePinner) {
        this.certificatePinner = certificatePinner;
    }

    @Override
    public OkHttpClient createNewNetworkModuleClient() {
        OkHttpClient.Builder client = OkHttpClientProvider.createClientBuilder();

        if (certificatePinner != null) {
            client.certificatePinner(certificatePinner);
        }
        
        return client.build();
    }
}