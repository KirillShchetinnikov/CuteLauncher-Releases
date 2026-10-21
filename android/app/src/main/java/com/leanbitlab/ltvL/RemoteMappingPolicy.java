package com.leanbitlab.ltvL;

import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

/** One action per gesture; timer and late UP share the same hold decision. */
final class RemoteMappingPolicy {
    static final long HOLD_MS = 650;
    record Decision(boolean consume, RemoteMappingConfiguration.Binding fire) {}
    private record Key(int device, int code) {}
    private static final class Press {
        final long downTime;
        final RemoteMappingConfiguration.Binding shortAction, holdAction;
        boolean fired, cancelled;
        Press(long time, RemoteMappingConfiguration.Binding shortAction, RemoteMappingConfiguration.Binding holdAction) {
            downTime = time; this.shortAction = shortAction; this.holdAction = holdAction;
        }
        boolean unchanged(RemoteMappingConfiguration.Binding shortNow, RemoteMappingConfiguration.Binding holdNow) {
            return !cancelled && Objects.equals(shortAction, shortNow) && Objects.equals(holdAction, holdNow);
        }
    }
    private final Map<Key, Press> pressed = new HashMap<>();
    Decision event(int device, int code, int action, int repeat, long downTime,
            boolean cancelled, RemoteMappingConfiguration.Binding binding) {
        return event(device, code, action, repeat, downTime, downTime, cancelled, binding, null);
    }
    Decision event(int device, int code, int action, int repeat, long downTime, long eventTime,
            boolean cancelled, RemoteMappingConfiguration.Binding shortNow, RemoteMappingConfiguration.Binding holdNow) {
        Key key = new Key(device, code);
        Press prior = pressed.get(key);
        if (prior != null && prior.downTime == downTime) {
            if (action == 1) {
                pressed.remove(key);
                if (cancelled || prior.fired || !prior.unchanged(shortNow, holdNow)) return new Decision(true, null);
                return new Decision(true, prior.holdAction != null && eventTime - downTime >= HOLD_MS
                    ? prior.holdAction : prior.shortAction);
            }
            return new Decision(true, null);
        }
        if (action == 0 && repeat == 0 && (shortNow != null || holdNow != null) && (prior != null || pressed.size() < 16)) {
            pressed.put(key, new Press(downTime, shortNow, holdNow));
            return new Decision(true, null);
        }
        return new Decision(false, null);
    }
    RemoteMappingConfiguration.Binding hold(int device, int code, long downTime, long now,
            RemoteMappingConfiguration.Binding shortNow, RemoteMappingConfiguration.Binding holdNow) {
        Press press = pressed.get(new Key(device, code));
        if (press == null || press.downTime != downTime || press.fired || press.holdAction == null
                || now - downTime < HOLD_MS || !press.unchanged(shortNow, holdNow)) return null;
        press.fired = true;
        return press.holdAction;
    }
    void clear() { pressed.clear(); }
    void cancelActions() { pressed.values().forEach(press -> press.cancelled = true); }
}
