/**
 * Agent action: create a return request. Thin wrapper over ReturnRequestService,
 * which holds the return policy.
 */
public with sharing class CreateReturnRequestAction {
    public class Request {
        @InvocableVariable(
            label='Partner Account ID'
            description='ID of the partner account that returns the product.'
            required=true
        )
        public Id accountId;

        @InvocableVariable(
            label='Requester Contact ID'
            description='Optional. ID of the partner contact who asks for the return.'
        )
        public Id contactId;

        @InvocableVariable(
            label='Order Number'
            description='Number of the delivered order, for example 00000103 or 103.'
            required=true
        )
        public String orderNumber;

        @InvocableVariable(
            label='Product'
            description='Product code or part of the product name, as it appears on the order.'
            required=true
        )
        public String product;

        @InvocableVariable(
            label='Quantity'
            description='Number of units to return. Whole number greater than zero.'
            required=true
        )
        public Integer quantity;

        @InvocableVariable(
            label='Reason'
            description='One of: Damaged in Transit, Wrong Item, Defective, Excess Stock, Other.'
            required=true
        )
        public String reason;

        @InvocableVariable(label='Description' description='Optional. Details from the partner in their own words.')
        public String description;
    }

    public class Response {
        @InvocableVariable(label='Success' description='True when the return request was created.')
        public Boolean success;

        @InvocableVariable(
            label='Error Code'
            description='Set when Success is false, for example NOT_DELIVERED, RETURN_WINDOW_CLOSED, QUANTITY_EXCEEDS_ORDER or ORDER_NOT_FOUND.'
        )
        public String errorCode;

        @InvocableVariable(
            label='Message'
            description='One sentence that explains the outcome. Pass it on to the partner.'
        )
        public String message;

        @InvocableVariable(
            label='Return Request Number'
            description='Number of the new return request, for example RR-00012.'
        )
        public String requestNumber;

        @InvocableVariable(label='Return Request ID' description='Record ID of the new return request.')
        public Id recordId;
    }

    @InvocableMethod(
        label='Create Return Request'
        description='Creates a return request for a product on a delivered order, after checking the 30-day return window and the returnable quantity.'
        category='Distributor'
    )
    public static List<Response> run(List<Request> requests) {
        List<ReturnRequestService.ReturnInput> inputs = new List<ReturnRequestService.ReturnInput>();
        for (Request request : requests) {
            ReturnRequestService.ReturnInput input = new ReturnRequestService.ReturnInput();
            input.accountId = request.accountId;
            input.contactId = request.contactId;
            input.orderNumber = request.orderNumber;
            input.product = request.product;
            input.quantity = request.quantity;
            input.reason = request.reason;
            input.description = request.description;
            inputs.add(input);
        }

        List<Response> responses = new List<Response>();
        for (ReturnRequestService.ReturnResult result : ReturnRequestService.createReturns(inputs)) {
            Response response = new Response();
            response.success = result.success;
            response.errorCode = result.errorCode;
            response.message = result.message;
            response.requestNumber = result.requestNumber;
            response.recordId = result.recordId;
            responses.add(response);
        }
        return responses;
    }
}
