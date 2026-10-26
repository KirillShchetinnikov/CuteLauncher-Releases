package com.leanbitlab.ltvL;

import java.util.*;

public final class TvCleanerRecoveryTest {
    static final String APP = "org.example.video", OTHER = "org.example.other";
    static final class Fake implements TvCleanerRecovery.Journal, TvCleanerRecovery.Device {
        final Map<String,Integer> actual = new LinkedHashMap<>(), pending = new LinkedHashMap<>();
        Map<String,Integer> persisted = new LinkedHashMap<>();
        final List<String> operations = new ArrayList<>();
        boolean failWrite, failCommand, ignoreCommand;
        public Integer original(String name) { return pending.get(name); }
        public void remember(String name, int before) { pending.put(name, before); }
        public Set<String> pending() { return pending.keySet(); }
        public void forget(String name) { pending.remove(name); }
        public void persist() throws Exception {
            operations.add("save");
            if (failWrite) throw new Exception("disk full");
            persisted = new LinkedHashMap<>(pending);
        }
        public int state(String name) { return actual.get(name); }
        public void set(String name, int state) throws Exception {
            if (!persisted.containsKey(name)) throw new AssertionError("Mutation before durable journal");
            operations.add("set");
            if (!ignoreCommand) actual.put(name,state);
            if (failCommand) throw new Exception("Disconnected after command");
        }
        void restart() { pending.clear(); pending.putAll(persisted); }
    }
    interface Action { void run() throws Exception; }
    static void fails(Action action) throws Exception {
        try { action.run(); } catch (Exception expected) { return; }
        throw new AssertionError("Expected failure");
    }
    static void check(boolean condition) { if (!condition) throw new AssertionError(); }
    public static void main(String[] args) throws Exception {
        for (int original=0; original<=4; original++) {
            Fake fake = new Fake(); fake.actual.put(APP,original);
            TvCleanerRecovery.apply(List.of(APP), original >= 2 ? 1 : 3, fake, fake);
            fake.restart(); // Simulate process death, not an in-memory undo.
            TvCleanerRecovery.restore(fake,fake);
            check(fake.actual.get(APP)==original && fake.persisted.isEmpty());
        }
        Fake disk = new Fake(); disk.actual.put(APP,0); disk.failWrite = true;
        fails(() -> TvCleanerRecovery.apply(List.of(APP),3,disk,disk));
        check(disk.actual.get(APP)==0 && !disk.operations.contains("set"));
        Fake lost = new Fake(); lost.actual.put(APP,0); lost.failCommand = true;
        fails(() -> TvCleanerRecovery.apply(List.of(APP),3,lost,lost));
        check(lost.actual.get(APP)==3 && lost.persisted.get(APP)==0);
        lost.restart(); lost.failCommand = false; TvCleanerRecovery.restore(lost,lost);
        check(lost.actual.get(APP)==0);
        Fake denied = new Fake(); denied.actual.put(APP,1); denied.ignoreCommand=true;
        fails(() -> TvCleanerRecovery.apply(List.of(APP),3,denied,denied));
        check(denied.persisted.get(APP)==1);
        denied.actual.put(APP,3);
        fails(() -> TvCleanerRecovery.restore(denied,denied));
        check(denied.persisted.get(APP)==1); // A denied recovery remains retryable.
        Fake skip = new Fake(); skip.actual.put(APP,2); skip.actual.put(OTHER,4);
        check(TvCleanerRecovery.apply(List.of(APP,OTHER),3,skip,skip)==0);
        check(skip.operations.isEmpty()); // Originally disabled packages are never enabled by undo.
        Fake repeat = new Fake(); repeat.actual.put(APP,0);
        TvCleanerRecovery.apply(List.of(APP),3,repeat,repeat);
        TvCleanerRecovery.apply(List.of(APP),1,repeat,repeat);
        check(repeat.persisted.get(APP)==0);
        TvCleanerRecovery.restore(repeat,repeat); check(repeat.actual.get(APP)==0);
        for (String invalid : List.of("com.a; reboot", "com.a\nreboot", "com.a'", "../a", "com.a/b", "com.a$(id)"))
            fails(() -> TvCleanerPolicy.command(invalid,3));
        for (String name : List.of("android", "com.android.systemui", "com.google.android.tungsten.setupwraith", "com.tcl.tvinput", "com.google.android.gms"))
            check(TvCleanerPolicy.critical(name));
        check(TvCleanerPolicy.command(APP,0).equals("pm default-state --user 0 'org.example.video'"));
        fails(() -> TvCleanerPolicy.command(APP,5));
        for (int i=0;i<=4;i++) check(TvCleanerPolicy.parseState("  User 10: installed=true enabled=1\n    User 0: ceDataInode=999 installed=true hidden=false stopped=false enabled=" + i + " instant=false\n") == i);
        // Full-state restoration covers externally changed packages as well as our journal.
        Fake full = new Fake(); full.actual.put(APP,3); full.actual.put(OTHER,1);
        check(TvCleanerRecovery.restoreStates(Map.of(APP,0,OTHER,4), Set.of(APP,OTHER), Set.of(), full,full)==0);
        check(full.actual.get(APP)==0 && full.actual.get(OTHER)==4);
        check(full.persisted.get(APP)==3 && full.persisted.get(OTHER)==1);
        Fake protectedApp = new Fake(); protectedApp.actual.put(APP,1);
        check(TvCleanerRecovery.restoreStates(Map.of(APP,3,OTHER,0), Set.of(APP), Set.of(APP), protectedApp,protectedApp)==2);
        check(protectedApp.operations.isEmpty());
        Fake partialState = new Fake(); partialState.actual.put(APP,3); partialState.failCommand=true;
        fails(() -> TvCleanerRecovery.restoreStates(Map.of(APP,0),Set.of(APP),Set.of(),partialState,partialState));
        partialState.restart(); partialState.failCommand=false;
        TvCleanerRecovery.restoreStates(Map.of(APP,0),Set.of(APP),Set.of(),partialState,partialState);
        check(partialState.actual.get(APP)==0);
        Fake badState = new Fake(); badState.actual.put(APP,0);
        var invalidStates = new LinkedHashMap<String,Integer>(); invalidStates.put(APP,3); invalidStates.put("bad;reboot",0);
        fails(() -> TvCleanerRecovery.restoreStates(invalidStates,Set.of(APP),Set.of(),badState,badState));
        check(badState.operations.isEmpty());
        fails(() -> TvCleanerPolicy.parseState("User 0: installed=false enabled=0"));
        fails(() -> TvCleanerPolicy.parseState("User 10: installed=true enabled=0"));
        fails(() -> TvCleanerPolicy.parseState("User 0: installed=true enabled=9"));
        System.out.println("TvCleanerRecoveryTest passed");
    }
}
