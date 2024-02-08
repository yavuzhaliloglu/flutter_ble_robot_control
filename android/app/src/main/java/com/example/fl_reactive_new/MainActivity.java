package com.example.fl_reactive_new;

import io.flutter.embedding.android.FlutterActivity;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.FlutterEngine;
import com.polidea.rxandroidble2.exceptions.BleException;
import io.reactivex.exceptions.UndeliverableException;
import io.reactivex.plugins.RxJavaPlugins;

public class MainActivity extends FlutterActivity {
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        RxJavaPlugins.setErrorHandler(throwable -> {
            if (throwable instanceof UndeliverableException && throwable.getCause() instanceof BleException) {
                System.out.println('!' * 80);
                System.out.println("Caught UndeliverableException from flutter_reactive_ble.");
                System.out.println('!' * 80);
                return; // ignore BleExceptions as they were surely delivered at least once
            }
            throw new RuntimeException("Unexpected Throwable in RxJavaPlugins error handler", throwable);
        });
    }
}
