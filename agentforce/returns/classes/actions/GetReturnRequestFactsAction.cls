/**
 * Apex grounding for the Explain_Return_Request prompt template. The template's free
 * text inputs map to Request by API name, so the names requestNumber and accountId
 * must match the template exactly. The result goes into the prompt as {Prompt}.
 */
public with sharing class GetReturnRequestFactsAction {
    public class Request {
        @InvocableVariable(label='Return Request Number' description='Number the partner gave, for example RR-00012 or 12.')
        public String requestNumber;

        @InvocableVariable(label='Partner Account ID' description='ID of the partner account from the agent session.')
        public String accountId;
    }

    public class Response {
        @InvocableVariable(label='Prompt' description='Facts about the return request and the return policy, as plain text.')
        public String Prompt;
    }

    @InvocableMethod(
        label='Get Return Request Facts'
        description='Returns the status, order, product, dates, resolution notes, next step and return policy for one return request of a partner.'
        category='Distributor'
    )
    public static List<Response> run(List<Request> requests) {
        List<ReturnRequestFactsService.FactsInput> inputs = new List<ReturnRequestFactsService.FactsInput>();
        for (Request request : requests) {
            ReturnRequestFactsService.FactsInput input = new ReturnRequestFactsService.FactsInput();
            input.requestNumber = request.requestNumber;
            input.accountId = request.accountId;
            inputs.add(input);
        }

        List<Response> responses = new List<Response>();
        for (String facts : ReturnRequestFactsService.describe(inputs, Date.today())) {
            Response response = new Response();
            response.Prompt = facts;
            responses.add(response);
        }
        return responses;
    }
}
