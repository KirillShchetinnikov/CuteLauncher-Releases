package com.leanbitlab.ltvL;
import java.util.*;
public class RecentTaskPolicyTest {
    public static void main(String[] args) {
        String live = "taskId=12: tv.first/.Main bounds=[] userId=0 visible=false\n"
            + "taskId=34: tv.second/.Main userId=0\n"
            + "taskId=56: tv.first/.Other userId=0\n"
            + "taskId=90: tv.foreign/.Main userId=10\n"
            + "taskId=91: tv.unknown/.Main\n";
        var tasks = RecentTaskPolicy.parse(live, "* Recent #0: Task{abc #34 type=standard}\n* Recent #1: Task{def #99}\n* Recent #2: Task{fff #12}");
        if (!tasks.equals(List.of(new RecentTaskPolicy.Task(34,"tv.second"), new RecentTaskPolicy.Task(12,"tv.first"), new RecentTaskPolicy.Task(56,"tv.first"))))
            throw new AssertionError(tasks);
        if (!RecentTaskPolicy.parse("", "* Recent #0: Task{abc #34}").isEmpty()) throw new AssertionError("No stale snapshots");
        var config = RemoteMappingConfiguration.fromMap(Map.of("enabled",true,"bindings",List.of(
            Map.of("keyCode",3,"enabled",true,"action","recents","target","","trigger","hold"))));
        if (!config.pressBinding(3).action().equals("home")) throw new AssertionError("Preserve short Home");
        var policy = new RemoteMappingPolicy();
        policy.event(1,3,0,0,100,100,false,config.pressBinding(3),config.binding(3,"hold"));
        if (!policy.event(1,3,1,0,100,200,false,config.pressBinding(3),config.binding(3,"hold")).fire().action().equals("home")) throw new AssertionError();
        policy.event(1,3,0,0,1000,1000,false,config.pressBinding(3),config.binding(3,"hold"));
        if (!policy.hold(1,3,1000,1650,config.pressBinding(3),config.binding(3,"hold")).action().equals("recents")) throw new AssertionError();
        if (policy.event(1,3,1,0,1000,1800,false,config.pressBinding(3),config.binding(3,"hold")).fire() != null) throw new AssertionError("No Home after hold");
        if (RemoteMappingConfiguration.assignable(3,"press") || RemoteMappingConfiguration.assignable(4,"hold")) throw new AssertionError("Protected buttons");
        System.out.println("RecentTaskPolicy and Home hold: passed");
    }
}
