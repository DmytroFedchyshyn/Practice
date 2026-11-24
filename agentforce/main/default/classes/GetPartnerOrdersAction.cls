/**
 * Agent action: order status. Thin wrapper over PartnerOrderService that maps the agent's
 * inputs and turns the result into text the LLM can read.
 */
public with sharing class GetPartnerOrdersAction {
    public class Request {
        @InvocableVariable(label='Partner Account ID' description='ID of the partner account whose orders to read.' required=true)
        public Id accountId;

        @InvocableVariable(
            label='Order Number'
            description='Order number to look up, for example 00000103 or 103. Leave empty to get the partner\'s most recent orders.'
        )
        public String orderNumber;
    }

    public class Response {
        @InvocableVariable(label='Success' description='True when the lookup worked, including when the partner has no orders.')
        public Boolean success;

        @InvocableVariable(label='Error Code' description='Set when Success is false, for example ORDER_NOT_FOUND or MISSING_ACCOUNT.')
        public String errorCode;

        @InvocableVariable(label='Message' description='One sentence that explains the outcome. Pass it on when Success is false.')
        public String message;

        @InvocableVariable(
            label='Orders'
            description='One line per order: number, placed date, fulfillment status, expected or actual delivery date, tracking number, warehouse, total and products.'
        )
        public String orders;
    }

    @InvocableMethod(
        label='Get Partner Orders'
        description='Returns the status of one partner order by its number, or the partner\'s most recent orders, with fulfillment status, delivery dates, tracking number and products.'
        category='Distributor'
    )
    public static List<Response> run(List<Request> requests) {
        List<PartnerOrderService.OrderLookup> lookups = new List<PartnerOrderService.OrderLookup>();
        for (Request request : requests) {
            lookups.add(new PartnerOrderService.OrderLookup(request.accountId, request.orderNumber));
        }

        List<Response> responses = new List<Response>();
        for (PartnerOrderService.OrderResult result : PartnerOrderService.getOrders(lookups)) {
            Response response = new Response();
            response.success = result.success;
            response.errorCode = result.errorCode;
            response.message = result.message;
            List<String> lines = new List<String>();
            for (PartnerOrderService.OrderSummary summary : result.orders) {
                lines.add(format(summary));
            }
            response.orders = String.join(lines, '\n');
            responses.add(response);
        }
        return responses;
    }

    @TestVisible
    private static String format(PartnerOrderService.OrderSummary summary) {
        List<String> parts = new List<String>{
            'Order ' + summary.orderNumber,
            'placed ' + String.valueOf(summary.placedOn),
            'status ' + summary.fulfillmentStatus
        };
        if (summary.deliveredDate != null) {
            parts.add('delivered ' + String.valueOf(summary.deliveredDate));
        } else if (summary.expectedDeliveryDate != null) {
            parts.add('expected delivery ' + String.valueOf(summary.expectedDeliveryDate));
        }
        if (String.isNotBlank(summary.trackingNumber)) {
            parts.add('tracking ' + summary.trackingNumber);
        }
        if (String.isNotBlank(summary.warehouse)) {
            parts.add('ships from ' + summary.warehouse);
        }
        if (summary.totalAmount != null) {
            parts.add('total ' + summary.totalAmount.setScale(2));
        }
        List<String> products = new List<String>();
        for (PartnerOrderService.OrderLine line : summary.lines) {
            products.add(line.quantity.intValue() + ' x ' + line.productName + ' (' + line.productCode + ')');
        }
        parts.add('products: ' + String.join(products, ', '));
        return String.join(parts, ' | ');
    }
}
