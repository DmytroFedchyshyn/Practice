public class Logger {
    private static Logger instance;

    private Logger() {}

    public static Logger getInstance() {
        if (instance == null) {
            instance = new Logger();
        }
        return instance;
    }

    public void log(LoggingLevel level, String message, String source) {
        if (level == LoggingLevel.INFO) {
            this.logInfo(message, source);
        } else if (level == LoggingLevel.WARN) {
            this.logWarning(message, source);
        } else if (level == LoggingLevel.ERROR) {
            this.logError(message, source);
        } else if(level == LoggingLevel.DEBUG) {
            this.logDebug(message, source);
        } else {
            throw new IllegalArgumentException('Invalid log level');
        }
    }

    public void logInfo(String message, String source) {
        LogEvent__e logEvent = this.createLogEvent(LoggingLevel.INFO, message, source);
        EventBus.publish(logEvent);
    }

    public void logWarning(String message, String source) {
        LogEvent__e logEvent = this.createLogEvent(LoggingLevel.WARN, message, source);
        EventBus.publish(logEvent);
    }

    public void logError(String message, String source) {
        LogEvent__e logEvent = this.createLogEvent(LoggingLevel.ERROR, message, source);
        EventBus.publish(logEvent);
    }

    public void logDebug(String message, String source) {
        LogEvent__e logEvent = this.createLogEvent(LoggingLevel.DEBUG, message, source);
        EventBus.publish(logEvent);
    }

    private LogEvent__e createLogEvent(LoggingLevel level, String message, String source) {
        LogEvent__e logEvent = new LogEvent__e();
        logEvent.Level__c = level.name();
        logEvent.Message__c = message;
        logEvent.Datetime__c = Datetime.now();
        logEvent.User__c = UserInfo.getUserId();
        logEvent.Source__c = source;
        return logEvent;
    }
}
