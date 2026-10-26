package com.leanbitlab.ltvL;

final class AppProcessPolicy {
    static boolean running(String output, String target, int uid) {
        for (String line : output.split("\\R")) {
            String[] fields = line.trim().split("\\s+", 2);
            if (fields.length != 2 || !fields[0].equals(Integer.toString(uid))) continue;
            String name = fields[1];
            if (name.equals(target) || name.startsWith(target + ":")) return true;
        }
        return false;
    }
}
