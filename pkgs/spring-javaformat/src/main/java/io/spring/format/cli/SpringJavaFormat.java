package io.spring.format.cli;

import io.spring.javaformat.config.JavaFormatConfig;
import io.spring.javaformat.formatter.StreamsFormatter;

import java.nio.file.Paths;

public final class SpringJavaFormat {

    public static void main(String[] args) {
        var pwd = Paths.get(args[0]);
        var config = JavaFormatConfig.findFrom(pwd);
        var formatter = new StreamsFormatter(config);
        formatter.format(System.in).writeTo((Appendable) System.out);
    }
}
