package com.criticalblue.reactnative;

import com.facebook.react.modules.network.OkHttpClientFactory;
import com.facebook.react.modules.network.OkHttpClientProvider;

import java.io.IOException;

import javax.net.ssl.SSLPeerUnverifiedException;

import io.sentry.Sentry;
import okhttp3.Call;
import okhttp3.CertificatePinner;
import okhttp3.EventListener;
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
            client.eventListener(new EventListener() {
                @Override
                public void callFailed(Call call, IOException ioe) {
                    if (ioe instanceof SSLPeerUnverifiedException) {
                        Sentry.captureException(ioe);
                    }
                }
            });
        }

        return client.build();
    }
}