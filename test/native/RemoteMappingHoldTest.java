package com.leanbitlab.ltvL;

import java.util.List;
import java.util.Map;

public class RemoteMappingHoldTest {
    private static void require(boolean ok, String message) { if (!ok) throw new AssertionError(message); }
    public static void main(String[] args) {
        var shortAction = new RemoteMappingConfiguration.Binding(190, true, "home", "", "press");
        var holdAction = new RemoteMappingConfiguration.Binding(190, true, "back", "", "hold");
        var config = RemoteMappingConfiguration.fromMap(Map.of("enabled",true,"bindings",List.of(shortAction.toMap(), holdAction.toMap())));
        require(config.binding(190).equals(shortAction) && config.binding(190,"hold").equals(holdAction), "Independent press and hold slots");
        require(RemoteMappingConfiguration.fromMap(config.toMap()).binding(190,"hold").equals(holdAction), "Hold survives round trip");
        var named = new RemoteMappingConfiguration.Binding(4137, true, "back", "", "hold", "My button");
        var namedConfig = RemoteMappingConfiguration.fromMap(Map.of("enabled",true,"bindings",List.of(named.toMap())));
        require(RemoteMappingConfiguration.fromMap(namedConfig.toMap()).binding(4137,"hold").name().equals("My button"), "Name survives native persistence round trip");
        require(shortAction.name().isEmpty(), "Unnamed mapping uses button label");
        var policy = new RemoteMappingPolicy();
        policy.event(5,190,0,0,100,100,false,shortAction,holdAction);
        require(policy.hold(5,190,100,749,shortAction,holdAction) == null, "Never fire before 650 ms");
        require(policy.event(5,190,1,0,100,749,false,shortAction,holdAction).fire().equals(shortAction), "Short release before threshold");
        policy.event(5,190,0,0,1000,1000,false,shortAction,holdAction);
        require(policy.hold(5,190,1000,1650,shortAction,holdAction).equals(holdAction), "Hold fires at threshold without repeat events");
        require(policy.hold(5,190,1000,1700,shortAction,holdAction) == null, "Hold fires once");
        require(policy.event(5,190,0,3,1000,1800,false,shortAction,holdAction).fire() == null, "Repeat does not fire again");
        require(policy.event(5,190,1,0,1000,1900,false,shortAction,holdAction).fire() == null, "Release after hold never fires short action");
        policy.event(5,190,0,0,2000,2000,false,shortAction,holdAction);
        require(policy.event(5,190,1,0,2000,2650,false,shortAction,holdAction).fire().equals(holdAction), "Late timer uses hold classification on UP");
        policy.event(5,190,0,0,3000,3000,false,shortAction,holdAction); policy.cancelActions();
        require(policy.hold(5,190,3000,3700,shortAction,holdAction) == null, "Interrupt cancels pending hold");
        require(policy.event(5,190,1,0,3000,3800,false,shortAction,holdAction).consume(), "Interrupted hold still consumes UP");
        policy.event(5,190,0,0,4000,4000,false,shortAction,holdAction);
        require(policy.hold(5,190,4000,4700,null,null) == null, "Suspension cancels hold execution");
        require(policy.event(5,190,1,0,4000,4800,true,shortAction,holdAction).fire() == null, "Cancelled release never fires late hold");
        policy.event(5,190,0,0,5000,5000,false,null,holdAction);
        require(policy.event(5,190,1,0,5000,5100,false,null,holdAction).fire() == null, "Hold-only short tap has no action");
        System.out.println("RemoteMappingHold: all checks passed");
    }
}
