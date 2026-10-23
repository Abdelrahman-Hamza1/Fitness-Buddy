package io.github.abdelrahmanhamza1.fitnessbuddy;

/** Pure ordering seam; Android supplies MODE_PRIVATE SharedPreferences commits. */
public final class SessionStorageCommitter {
    // flutter_secure_storage 11.2.0, AndroidOptions.storageNamespace below.
    // Wrapped key and algorithm markers must reach disk before ciphertext.
    private static final String[] STORES = {
        "FlutterSecureKeyStorage:fb.session.secure.v1",
        "FlutterSecureStorageConfiguration:fb.session.secure.v1",
        "fb.session.secure.v1"
    };
    public static final String BARRIER_KEY = "fb_session_commit_barrier_v1";

    public interface Store {
        boolean commit(String name) throws Exception;
    }

    public static boolean commit(Store store) throws Exception {
        for (String name : STORES) {
            if (!store.commit(name)) return false;
        }
        return true;
    }

    private SessionStorageCommitter() {}
}
