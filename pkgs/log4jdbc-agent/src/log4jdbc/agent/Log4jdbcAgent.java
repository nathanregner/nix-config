package log4jdbc.agent;

/**
 * The JVM appends -javaagent jars to the system class path, which is the only reason this agent exists: it puts
 * log4jdbc on the class path of apps whose launcher (e.g. IntelliJ) builds -cp itself.
 */
public final class Log4jdbcAgent {

	public static void premain(String args) {
	}

}
