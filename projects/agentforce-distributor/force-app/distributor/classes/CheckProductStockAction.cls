/**
 * Agent action: stock availability. Thin wrapper over StockAvailabilityService.
 * Stock is not partner-specific, so this action does not take an account.
 */
public with sharing class CheckProductStockAction {
    public class Request {
        @InvocableVariable(
            label='Product'
            description='Product code, for example DST-1001, or part of the product name, for example drill.'
            required=true
        )
        public String product;
    }

    public class Response {
        @InvocableVariable(label='Success' description='True when stock was found for one or more products, including when the stock is zero.')
        public Boolean success;

        @InvocableVariable(label='Error Code' description='Set when Success is false: PRODUCT_NOT_FOUND, AMBIGUOUS_PRODUCT or PRODUCT_REQUIRED.')
        public String errorCode;

        @InvocableVariable(label='Message' description='One sentence that explains the outcome. On AMBIGUOUS_PRODUCT it lists the matching products.')
        public String message;

        @InvocableVariable(label='Stock' description='One line per product: total units available to order and the split per warehouse.')
        public String stock;
    }

    @InvocableMethod(
        label='Check Product Stock'
        description='Returns how many units of a product are available to order, in total and per warehouse. Available means on hand minus reserved for open orders.'
        category='Distributor'
    )
    public static List<Response> run(List<Request> requests) {
        List<String> terms = new List<String>();
        for (Request request : requests) {
            terms.add(request.product);
        }

        List<Response> responses = new List<Response>();
        for (StockAvailabilityService.StockResult result : StockAvailabilityService.checkStock(terms)) {
            Response response = new Response();
            response.success = result.success;
            response.errorCode = result.errorCode;
            response.message = result.message;
            List<String> lines = new List<String>();
            for (StockAvailabilityService.ProductStock product : result.products) {
                lines.add(format(product));
            }
            response.stock = String.join(lines, '\n');
            responses.add(response);
        }
        return responses;
    }

    @TestVisible
    private static String format(StockAvailabilityService.ProductStock product) {
        List<String> warehouses = new List<String>();
        for (StockAvailabilityService.WarehouseStock warehouse : product.warehouses) {
            warehouses.add(
                warehouse.warehouseName + ' (' + warehouse.city + '): ' + warehouse.available + ' available of ' + warehouse.onHand + ' on hand'
            );
        }
        String summary = product.productName + ' (' + product.productCode + '): ' + product.totalAvailable + ' available in total';
        return warehouses.isEmpty() ? summary + '. Not stocked in any active warehouse.' : summary + '. ' + String.join(warehouses, '; ') + '.';
    }
}
