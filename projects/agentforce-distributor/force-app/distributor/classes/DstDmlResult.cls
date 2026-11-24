/**
 * The outcome of one record of an ...Each write: its Id when saved, otherwise the first error's status
 * code and the messages of every error.
 */
public inherited sharing class DstDmlResult {
    public Id recordId { get; private set; }
    public Boolean success { get; private set; }
    public String statusCode { get; private set; }
    public List<String> messages { get; private set; }

    public DstDmlResult(Id recordId, Boolean success, String statusCode, List<String> messages) {
        this.recordId = recordId;
        this.success = success;
        this.statusCode = statusCode;
        this.messages = messages == null ? new List<String>() : messages;
    }

    /** The first error's message, or null when the record was saved. */
    public String firstMessage() {
        return messages.isEmpty() ? null : messages[0];
    }

    public static List<DstDmlResult> of(List<Database.SaveResult> saves) {
        List<DstDmlResult> results = new List<DstDmlResult>();
        for (Database.SaveResult save : saves) {
            List<String> messages = new List<String>();
            String statusCode;
            for (Database.Error error : save.getErrors()) {
                statusCode = statusCode == null ? String.valueOf(error.getStatusCode()) : statusCode;
                messages.add(error.getMessage());
            }
            results.add(new DstDmlResult(save.getId(), save.isSuccess(), statusCode, messages));
        }
        return results;
    }
}
