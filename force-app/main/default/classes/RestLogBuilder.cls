/**
 * Created by DDiaconescu on 19/11/2018.
 */

/**
* RestLogBuilder.cls
* Description: defines the log builder to easily build a log record and insert it
**/
public with sharing class RestLogBuilder{
    /**
    * @description Constants used in the log builder
    */
    @TestVisible public static final String LOG_LEVEL_ALL = 'All';
    @TestVisible public static final String LOG_LEVEL_FAILURE = 'Failure';
    @TestVisible public static final String LOG_LEVEL_NONE = 'None';
    @TestVisible public static final String STATUS_SUCCESS = 'Success';
    @TestVisible public static final String STATUS_FAILURE = 'Failure';
    private static final Integer TEXT_MAX_NUMBER_CHARS = 255;
    private static final Integer TEXTAREA_MAX_NUMBER_CHARS = 131072;

    /**
    * @description defines log level (create a setting for this)
    */
    @TestVisible public String logLevel = LOG_LEVEL_ALL;

    /**
    * @description defines log record that will be inserted or logged out
    */
    public Rest_Log__c log;
    public Rest_Log_Event__e logEvent;

    /**
    * @description constructor which leverages the SObjectBuilder to initiate record
    */
    public RestLogBuilder() {
        this.log = new Rest_Log__c();
        this.logEvent = new Rest_Log_Event__e();
    }

    /**
    * @description set log level
    * @param DateTime startTime
    */
    public RestLogBuilder withLogLevel(String logLevel) {
        this.logLevel = logLevel;
        return this;
    }

    /**
    * @description set start time
    * @param DateTime startTime
    */
    public RestLogBuilder withStartTime(Datetime startTime) {
        this.log.Start_Time__c = startTime;
        this.logEvent.Start_Time__c = startTime;
        return this;
    }

    /**
    * @description set end time
    * @param DateTime endTime
    */
    public RestLogBuilder withEndTime(Datetime startTime) {
        this.log.End_Time__c = startTime;
        this.logEvent.End_Time__c = startTime;
        return this;
    }

    /**
    * @description set method
    * @param String method
    */
    public RestLogBuilder withMethod(String method) {
        this.log.Method__c = this.cleanUp(method, TEXT_MAX_NUMBER_CHARS);
        this.logEvent.Method__c = this.cleanUp(method, TEXT_MAX_NUMBER_CHARS);
        return this;
    }

    /**
    * @description set endpoint
    * @param String endpoint
    */
    public RestLogBuilder withEndpoint(String endpoint) {
        this.log.Endpoint__c = this.cleanUp(endpoint, TEXT_MAX_NUMBER_CHARS);
        this.logEvent.Endpoint__c = this.cleanUp(endpoint, TEXT_MAX_NUMBER_CHARS);
        return this;
    }

    /**
    * @description set requestBody
    * @param String requestBody
    */
    public RestLogBuilder withRequestBody(String requestBody) {
        this.log.Request_Body__c = this.cleanUp(requestBody, TEXTAREA_MAX_NUMBER_CHARS);
        this.logEvent.Request_Body__c = this.cleanUp(requestBody, TEXTAREA_MAX_NUMBER_CHARS);
        return this;
    }

    /**
    * @description set responseBody
    * @param String responseBody
    */
    public RestLogBuilder withResponseBody(String responseBody) {
        this.log.Response_Body__c = this.cleanUp(responseBody, TEXTAREA_MAX_NUMBER_CHARS);
        this.logEvent.Response_Body__c = this.cleanUp(responseBody, TEXTAREA_MAX_NUMBER_CHARS);
        return this;
    }

    /**
    * @description set Message and StackTrace from exception
    * @param Exception ex
    */
    public RestLogBuilder withException(Exception ex) {
        this.log.Message__c = this.cleanUp(ex.getMessage(), TEXTAREA_MAX_NUMBER_CHARS);
        this.log.Stack_Trace__c = this.cleanUp(ex.getStackTraceString(), TEXTAREA_MAX_NUMBER_CHARS);
        this.logEvent.Message__c = this.cleanUp(ex.getMessage(), TEXTAREA_MAX_NUMBER_CHARS);
        this.logEvent.Stack_Trace__c = this.cleanUp(ex.getStackTraceString(), TEXTAREA_MAX_NUMBER_CHARS);
        return this;
    }

    /**
    * @description set errorCode
    * @param String errorCode
    */
    public RestLogBuilder withErrorCode(String errorCode) {
        this.log.Error_Code__c = this.cleanUp(errorCode, TEXT_MAX_NUMBER_CHARS);
        this.logEvent.Error_Code__c = this.cleanUp(errorCode, TEXT_MAX_NUMBER_CHARS);
        this.log.Status__c = this.getStatus();
        this.logEvent.Status__c = this.getStatusEvent();
        return this;
    }


    /**
   * @description set the event log
   */
    public RestLogBuilder withEventLog() {
        this.logEvent.Status__c = this.getStatusEvent();
        if (this.logLevel == LOG_LEVEL_NONE) {
            this.logEvent = null;
        } else if (this.logLevel == LOG_LEVEL_FAILURE && this.logEvent.Status__c != STATUS_FAILURE) {
            this.logEvent = null;
        }
        return this;
    }

    /**
    * @description insert or log out log record depending on log level
    */
    public RestLogBuilder insertLog() {
        this.log.Status__c = this.getStatus();
        if(this.logLevel == LOG_LEVEL_ALL || this.log.Status__c == STATUS_FAILURE) {
            insert this.log;
        } else {
            System.debug('===> Log: ' + this.log);
        }
        return this;
    }


    /**
    * @description queue insert or log out log record depending on log level
    */
    public RestLogBuilder queueLog() {
        this.log.Status__c = this.getStatus();
        if(this.logLevel == LOG_LEVEL_ALL || this.log.Status__c == STATUS_FAILURE) {
            if(Limits.getQueueableJobs() != Limits.getLimitQueueableJobs()) {
                System.enqueueJob(new queueRestLog(this.log));
            }
        } else {
            System.debug('===> Log: ' + this.log);
        }
        return this;
    }


    /**
    * @description platform event publish or log out log record depending on log level
    */
    public RestLogBuilder eventLog() {
        this.logEvent.Status__c = this.getStatusEvent();
        if(this.logLevel == LOG_LEVEL_ALL || this.logEvent.Status__c == STATUS_FAILURE) {
            // Call method to publish events
            Database.SaveResult saveResult = EventBus.publish(this.logEvent);
            // Inspect publishing result for each event
            if (saveResult.isSuccess()) {
                System.debug('Successfully published event.');
            } else {
                for(Database.Error err : saveResult.getErrors()) {
                    System.debug('Error returned: ' +
                            err.getStatusCode() +
                            ' - ' +
                            err.getMessage());
                }
            }
        } else {
            System.debug('===> Log: ' + this.log);
        }
        return this;
    }

    /**
    * @description returns the log record
    * @return Rest_Log__c log
    */
    public Rest_Log__c build() {
        return this.log;
    }

    /**
    * @description returns the log record
    * @return Rest_Log__c log
    */
    public Rest_Log_Event__e buildEvent() {
        return this.logEvent;
    }

    /**
    * @description returns the status depending if an errorCode is set or not
    * @return String status
    */
    private String getStatus() {
        if(this.log.Error_Code__c == null) {
            return STATUS_SUCCESS;
        } else {
            return STATUS_FAILURE;
        }
    }

    /**
    * @description returns the status depending if an errorCode is set or not
    * @return String status
    */
    private String getStatusEvent() {
        if(this.logEvent.Error_Code__c == null) {
            return STATUS_SUCCESS;
        } else {
            return STATUS_FAILURE;
        }
    }

    /**
    * @description returns a cleaned up string, not null and length cut
    * @param String stringToCleanUp
    * @param Integer stringMaxLength
    * @return String cleanedString
    */
    private String cleanUp(String stringToCleanUp, Integer stringMaxLength) {
        return (stringToCleanUp != null && stringToCleanUp.length() > stringMaxLength ? stringToCleanUp.left(stringMaxLength) : stringToCleanUp);
    }


    /**
    * queueRestLog.cls
    * Description: queue insert rest log
    **/
    public class queueRestLog implements Queueable {

        private Rest_Log__c restLog;

        public queueRestLog(Rest_Log__c restLog){
            this.restLog = restLog;
        }
        public void execute(QueueableContext context) {
            insert restLog;
        }
    }

}