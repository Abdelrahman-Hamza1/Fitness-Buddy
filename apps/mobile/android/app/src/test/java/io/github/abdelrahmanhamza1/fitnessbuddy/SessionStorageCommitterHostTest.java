package io.github.abdelrahmanhamza1.fitnessbuddy;

import org.junit.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.FutureTask;
import java.util.concurrent.TimeUnit;

/** Host-only ordering tests. Does not claim to emulate Android disk persistence. */
public final class SessionStorageCommitterHostTest {
    @Test
    public void commitsAllStoresInDependencyOrder() throws Exception {
        List<String> names = new ArrayList<>();
        check(SessionStorageCommitter.commit(name -> { names.add(name); return true; }));
        check(names.equals(List.of("FlutterSecureKeyStorage:fb.session.secure.v1",
                "FlutterSecureStorageConfiguration:fb.session.secure.v1", "fb.session.secure.v1")));
        check(!SessionStorageCommitter.BARRIER_KEY.contains(
                "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIHNlY3VyZSBzdG9yYWdlCg"));
    }

    private void failsAt(int failingIndex) throws Exception {
        List<String> attempted = new ArrayList<>();
        check(!SessionStorageCommitter.commit(name -> {
            attempted.add(name);
            return attempted.size() != failingIndex + 1;
        }));
        check(attempted.size() == failingIndex + 1);
    }

    @Test public void stopsOnKeyStoreFailure() throws Exception { failsAt(0); }
    @Test public void stopsOnConfigurationFailure() throws Exception { failsAt(1); }
    @Test public void stopsOnEnvelopeFailure() throws Exception { failsAt(2); }

    @Test(expected = Exception.class)
    public void propagatesFailureWithoutAcknowledgement() throws Exception {
        SessionStorageCommitter.commit(name -> { throw new Exception("synthetic"); });
    }

    @Test
    public void waitsForDiskWorkBeforeAcknowledgement() throws Exception {
        CountDownLatch entered = new CountDownLatch(1);
        CountDownLatch release = new CountDownLatch(1);
        FutureTask<Boolean> pending = new FutureTask<>(() -> SessionStorageCommitter.commit(name -> {
            entered.countDown();
            check(release.await(5, TimeUnit.SECONDS));
            return true;
        }));
        Thread thread = new Thread(pending);
        thread.start();
        check(entered.await(5, TimeUnit.SECONDS));
        check(!pending.isDone()); // No successful acknowledgement while disk work is held.
        release.countDown();
        check(pending.get(5, TimeUnit.SECONDS));
        thread.join();
    }

    private static void check(boolean value) { if (!value) throw new AssertionError(); }
}
