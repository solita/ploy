package fi.solita.deployer;

import java.util.*;

public class Main {
    public static void main(String[] originalArgs) {
        List<String> args = new ArrayList<String>();
        args.add("--1.9");
        args.add("classpath:main.rb");
        Collections.addAll(args, originalArgs);

        org.jruby.Main.main(args.toArray(new String[args.size()]));
    }
}
