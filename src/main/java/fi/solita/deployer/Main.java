package fi.solita.deployer;

import java.util.*;

public class Main {
    public static void main(String[] originalArgs) {
        List<String> args = new ArrayList<String>();
        args.add("classpath:jar-bootstrap.rb");
        Collections.addAll(args, originalArgs);

        System.setProperty("jruby.compat.version", "1.9");

        org.jruby.Main.main(args.toArray(new String[args.size()]));
    }
}
