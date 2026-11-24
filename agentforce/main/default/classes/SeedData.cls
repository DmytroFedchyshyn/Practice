/**
 * Loads a small, repeatable demo data set for the distributor scenario:
 * partner accounts and contacts, products with prices, warehouses with stock,
 * orders in every fulfillment status and a few return requests.
 *
 * Safe to run more than once. Reference data is matched on external ids or
 * product codes and updated in place; orders and return requests of the seeded
 * partners are deleted and rebuilt so that their dates stay relative to today.
 *
 * All companies, people and numbers are invented.
 */
public with sharing class SeedData {
    @TestVisible
    private static final String PRODUCT_CODE_PREFIX = 'DST-';
    @TestVisible
    private static final String PRICE_BOOK_NAME = 'Distributor Partner Price Book';

    // Partner code, name, tier, city
    private static final List<List<String>> PARTNER_ROWS = new List<List<String>>{
        new List<String>{ 'BOR-001', 'Borealis Hardware', 'Gold', 'Kyiv' },
        new List<String>{ 'KES-002', 'Kestrel Supply Co', 'Silver', 'Lviv' },
        new List<String>{ 'MAR-003', 'Marlow and Finch Trading', 'Platinum', 'Odesa' }
    };

    // Partner code, first name, last name, email
    private static final List<List<String>> CONTACT_ROWS = new List<List<String>>{
        new List<String>{ 'BOR-001', 'Olena', 'Hrytsenko', 'olena.hrytsenko@borealis.example.com' },
        new List<String>{ 'BOR-001', 'Taras', 'Melnyk', 'taras.melnyk@borealis.example.com' },
        new List<String>{ 'KES-002', 'Iryna', 'Savchuk', 'iryna.savchuk@kestrel.example.com' },
        new List<String>{ 'KES-002', 'Andrii', 'Bondar', 'andrii.bondar@kestrel.example.com' },
        new List<String>{ 'MAR-003', 'Sofiia', 'Kovalenko', 'sofiia.kovalenko@marlowfinch.example.com' },
        new List<String>{ 'MAR-003', 'Maksym', 'Tkachuk', 'maksym.tkachuk@marlowfinch.example.com' }
    };

    // Warehouse code, name, city
    private static final List<List<String>> WAREHOUSE_ROWS = new List<List<String>>{
        new List<String>{ 'CEN', 'Central Warehouse', 'Kyiv' },
        new List<String>{ 'WST', 'West Warehouse', 'Lviv' }
    };

    // Code, name, family, unit price, then on hand and reserved per warehouse (CEN, WST).
    // The mix is deliberate: plenty, low, fully reserved and out of stock.
    private static final List<List<Object>> PRODUCT_ROWS = new List<List<Object>>{
        new List<Object>{ 'DST-1001', 'Cordless Drill 18V', 'Power Tools', 129.00, 240, 30, 85, 10 },
        new List<Object>{ 'DST-1002', 'Angle Grinder 125 mm', 'Power Tools', 89.50, 120, 0, 0, 0 },
        new List<Object>{ 'DST-1003', 'Rotary Hammer SDS-Plus', 'Power Tools', 214.00, 8, 6, 15, 0 },
        new List<Object>{ 'DST-2001', 'Socket Set 94 pcs', 'Hand Tools', 74.90, 310, 45, 140, 20 },
        new List<Object>{ 'DST-2002', 'Torque Wrench 40-200 Nm', 'Hand Tools', 96.00, 0, 0, 0, 0 },
        new List<Object>{ 'DST-2003', 'Spirit Level 1200 mm', 'Hand Tools', 32.40, 60, 60, 25, 5 },
        new List<Object>{ 'DST-3001', 'Wood Screws 4x40 (box of 1000)', 'Fasteners', 18.75, 900, 120, 400, 0 },
        new List<Object>{ 'DST-3002', 'Anchor Bolts M10 (box of 50)', 'Fasteners', 27.30, 45, 10, 5, 5 }
    };

    // Days since the order was placed, fulfillment status, days until expected delivery
    // (negative is in the past), days since delivery (null when not delivered).
    // The standard return window in the scenario is 30 days: order 3 is inside it, order 4 outside.
    private static final List<List<Object>> ORDER_SHAPES = new List<List<Object>>{
        new List<Object>{ 1, 'Processing', 6, null },
        new List<Object>{ 3, 'Picking', 4, null },
        new List<Object>{ 6, 'Shipped', 2, null },
        new List<Object>{ 20, 'Delivered', -12, 12 },
        new List<Object>{ 90, 'Delivered', -80, 80 },
        new List<Object>{ 15, 'Cancelled', null, null }
    };

    // Partner code, index into ORDER_SHAPES, reason, status, resolution notes
    private static final List<List<Object>> RETURN_ROWS = new List<List<Object>>{
        new List<Object>{ 'BOR-001', 3, 'Damaged in Transit', 'Under Review', null },
        new List<Object>{ 'KES-002', 3, 'Wrong Item', 'Approved', 'Approved. A prepaid return label was sent to the requester.' },
        new List<Object>{ 'MAR-003', 4, 'Defective', 'Rejected', 'Rejected: the order was delivered outside the 30-day return window.' }
    };

    /**
     * Loads or refreshes the demo data.
     * @return record counts by object API name, for logging
     */
    public static Map<String, Integer> run() {
        Map<String, Account> accounts = upsertAccounts();
        Map<String, Contact> primaryContacts = upsertContacts(accounts);
        Map<String, Product2> products = upsertProducts();
        Id priceBookId = upsertPriceBook();
        Map<Id, PricebookEntry> entries = upsertPriceBookEntries(products.values(), priceBookId);
        Map<String, Warehouse__c> warehouses = upsertWarehouses();
        List<Stock_Level__c> stock = upsertStockLevels(products, warehouses);

        deleteTransactions(accounts.values());
        Map<String, List<Order>> orders = insertOrders(accounts, products.values(), entries, priceBookId, warehouses);
        List<Return_Request__c> returns = insertReturns(accounts, primaryContacts, orders);

        Integer orderCount = 0;
        for (List<Order> partnerOrders : orders.values()) {
            orderCount += partnerOrders.size();
        }
        return new Map<String, Integer>{
            'Account' => accounts.size(),
            'Contact' => CONTACT_ROWS.size(),
            'Product2' => products.size(),
            'Warehouse__c' => warehouses.size(),
            'Stock_Level__c' => stock.size(),
            'Order' => orderCount,
            'Return_Request__c' => returns.size()
        };
    }

    private static Map<String, Account> upsertAccounts() {
        List<Account> records = new List<Account>();
        for (List<String> row : PARTNER_ROWS) {
            records.add(new Account(Partner_Code__c = row[0], Name = row[1], Partner_Tier__c = row[2], BillingCity = row[3]));
        }
        upsert records Partner_Code__c;

        Map<String, Account> byCode = new Map<String, Account>();
        for (Account record : records) {
            byCode.put(record.Partner_Code__c, record);
        }
        return byCode;
    }

    /** @return the first contact of every partner, keyed by partner code */
    private static Map<String, Contact> upsertContacts(Map<String, Account> accounts) {
        Set<String> emails = new Set<String>();
        for (List<String> row : CONTACT_ROWS) {
            emails.add(row[3]);
        }
        Map<String, Contact> existing = new Map<String, Contact>();
        for (Contact record : [SELECT Id, Email FROM Contact WHERE Email IN :emails]) {
            existing.put(record.Email, record);
        }

        List<Contact> records = new List<Contact>();
        Map<String, Contact> primaryByCode = new Map<String, Contact>();
        for (List<String> row : CONTACT_ROWS) {
            Contact record = existing.containsKey(row[3]) ? existing.get(row[3]) : new Contact(Email = row[3]);
            record.AccountId = accounts.get(row[0]).Id;
            record.FirstName = row[1];
            record.LastName = row[2];
            records.add(record);
            if (!primaryByCode.containsKey(row[0])) {
                primaryByCode.put(row[0], record);
            }
        }
        upsert records;
        return primaryByCode;
    }

    private static Map<String, Product2> upsertProducts() {
        Map<String, Product2> byCode = new Map<String, Product2>();
        for (Product2 record : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode LIKE :(PRODUCT_CODE_PREFIX + '%')]) {
            byCode.put(record.ProductCode, record);
        }
        for (List<Object> row : PRODUCT_ROWS) {
            String code = (String) row[0];
            Product2 record = byCode.containsKey(code) ? byCode.get(code) : new Product2(ProductCode = code);
            record.Name = (String) row[1];
            record.Family = (String) row[2];
            record.IsActive = true;
            byCode.put(code, record);
        }
        upsert byCode.values();
        return byCode;
    }

    /**
     * Orders need an active price book. The seed keeps its own instead of
     * activating or editing the org's standard price book.
     */
    private static Id upsertPriceBook() {
        List<Pricebook2> existing = [SELECT Id FROM Pricebook2 WHERE Name = :PRICE_BOOK_NAME AND IsStandard = FALSE LIMIT 1];
        Pricebook2 record = existing.isEmpty() ? new Pricebook2(Name = PRICE_BOOK_NAME) : existing[0];
        record.IsActive = true;
        record.Description = 'Partner prices for the distributor demo data.';
        upsert record;
        return record.Id;
    }

    /**
     * A product needs a standard price before it can be added to any other
     * price book, so every product gets two entries.
     * @return entries of the partner price book, keyed by product id
     */
    private static Map<Id, PricebookEntry> upsertPriceBookEntries(List<Product2> products, Id priceBookId) {
        Id standardId = Test.isRunningTest()
            ? Test.getStandardPricebookId()
            : [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1].Id;

        Map<String, Decimal> priceByCode = new Map<String, Decimal>();
        for (List<Object> row : PRODUCT_ROWS) {
            priceByCode.put((String) row[0], (Decimal) row[3]);
        }

        Map<String, PricebookEntry> existing = new Map<String, PricebookEntry>();
        for (PricebookEntry entry : [
            SELECT Id, Product2Id, Pricebook2Id
            FROM PricebookEntry
            WHERE Product2Id IN :products AND Pricebook2Id IN (:standardId, :priceBookId)
        ]) {
            existing.put(entry.Pricebook2Id + ':' + entry.Product2Id, entry);
        }

        // Standard entries first: the list is processed in order within one DML statement.
        List<PricebookEntry> records = new List<PricebookEntry>();
        for (Id bookId : new List<Id>{ standardId, priceBookId }) {
            for (Product2 product : products) {
                String key = bookId + ':' + product.Id;
                PricebookEntry entry = existing.containsKey(key)
                    ? existing.get(key)
                    : new PricebookEntry(Pricebook2Id = bookId, Product2Id = product.Id);
                entry.UnitPrice = priceByCode.get(product.ProductCode);
                entry.IsActive = true;
                records.add(entry);
            }
        }
        upsert records;

        Map<Id, PricebookEntry> partnerEntries = new Map<Id, PricebookEntry>();
        for (PricebookEntry entry : records) {
            if (entry.Pricebook2Id == priceBookId) {
                partnerEntries.put(entry.Product2Id, entry);
            }
        }
        return partnerEntries;
    }

    private static Map<String, Warehouse__c> upsertWarehouses() {
        List<Warehouse__c> records = new List<Warehouse__c>();
        for (List<String> row : WAREHOUSE_ROWS) {
            records.add(new Warehouse__c(Code__c = row[0], Name = row[1], City__c = row[2], Is_Active__c = true));
        }
        upsert records Code__c;

        Map<String, Warehouse__c> byCode = new Map<String, Warehouse__c>();
        for (Warehouse__c record : records) {
            byCode.put(record.Code__c, record);
        }
        return byCode;
    }

    private static List<Stock_Level__c> upsertStockLevels(Map<String, Product2> products, Map<String, Warehouse__c> warehouses) {
        Map<String, Stock_Level__c> existing = new Map<String, Stock_Level__c>();
        for (Stock_Level__c record : [
            SELECT Id, Stock_Key__c
            FROM Stock_Level__c
            WHERE Stock_Key__c LIKE :('%:' + PRODUCT_CODE_PREFIX + '%')
        ]) {
            existing.put(record.Stock_Key__c, record);
        }

        List<Stock_Level__c> records = new List<Stock_Level__c>();
        for (List<Object> row : PRODUCT_ROWS) {
            String productCode = (String) row[0];
            for (Integer i = 0; i < WAREHOUSE_ROWS.size(); i++) {
                String warehouseCode = WAREHOUSE_ROWS[i][0];
                String key = warehouseCode + ':' + productCode;
                // The master-detail to the warehouse cannot be changed after insert,
                // so parents are only set on new rows.
                Stock_Level__c record = existing.containsKey(key)
                    ? existing.get(key)
                    : new Stock_Level__c(
                          Stock_Key__c = key,
                          Warehouse__c = warehouses.get(warehouseCode).Id,
                          Product__c = products.get(productCode).Id
                      );
                record.Quantity_On_Hand__c = (Integer) row[4 + i * 2];
                record.Quantity_Reserved__c = (Integer) row[5 + i * 2];
                record.Last_Synced__c = System.now();
                records.add(record);
            }
        }
        upsert records;
        return records;
    }

    /** Activated orders cannot be deleted, so they go back to Draft first. */
    private static void deleteTransactions(List<Account> accounts) {
        delete [SELECT Id FROM Return_Request__c WHERE Account__c IN :accounts];

        List<Order> orders = [SELECT Id, Status FROM Order WHERE AccountId IN :accounts];
        List<Order> activated = new List<Order>();
        for (Order record : orders) {
            if (record.Status == 'Activated') {
                record.Status = 'Draft';
                activated.add(record);
            }
        }
        update activated;
        delete orders;
    }

    /** @return orders per partner code, in the same order as ORDER_SHAPES */
    private static Map<String, List<Order>> insertOrders(
        Map<String, Account> accounts,
        List<Product2> products,
        Map<Id, PricebookEntry> entries,
        Id priceBookId,
        Map<String, Warehouse__c> warehouses
    ) {
        Date today = Date.today();
        Map<String, List<Order>> byPartner = new Map<String, List<Order>>();
        List<Order> orders = new List<Order>();

        for (Integer p = 0; p < PARTNER_ROWS.size(); p++) {
            String partnerCode = PARTNER_ROWS[p][0];
            List<Order> partnerOrders = new List<Order>();
            for (Integer s = 0; s < ORDER_SHAPES.size(); s++) {
                List<Object> shape = ORDER_SHAPES[s];
                String fulfillment = (String) shape[1];
                Integer expectedIn = (Integer) shape[2];
                Integer deliveredAgo = (Integer) shape[3];
                Boolean hasShipped = fulfillment == 'Shipped' || fulfillment == 'Delivered';

                partnerOrders.add(
                    new Order(
                        AccountId = accounts.get(partnerCode).Id,
                        Pricebook2Id = priceBookId,
                        EffectiveDate = today.addDays(-(Integer) shape[0]),
                        Status = 'Draft',
                        Fulfillment_Status__c = fulfillment,
                        Fulfillment_Warehouse__c = warehouses.get(WAREHOUSE_ROWS[Math.mod(p + s, WAREHOUSE_ROWS.size())][0]).Id,
                        Expected_Delivery_Date__c = expectedIn == null ? null : today.addDays(expectedIn),
                        Delivered_Date__c = deliveredAgo == null ? null : today.addDays(-deliveredAgo),
                        Tracking_Number__c = hasShipped ? 'TRK-' + partnerCode + '-' + (s + 1) : null
                    )
                );
            }
            byPartner.put(partnerCode, partnerOrders);
            orders.addAll(partnerOrders);
        }
        insert orders;

        // Two lines per order, spread over the catalogue so partners differ.
        List<OrderItem> items = new List<OrderItem>();
        for (Integer p = 0; p < PARTNER_ROWS.size(); p++) {
            List<Order> partnerOrders = byPartner.get(PARTNER_ROWS[p][0]);
            for (Integer s = 0; s < partnerOrders.size(); s++) {
                Product2 first = products[Math.mod(p + s, products.size())];
                Product2 second = products[Math.mod(p + s + 3, products.size())];
                items.add(newItem(partnerOrders[s], entries.get(first.Id), 5 + s));
                items.add(newItem(partnerOrders[s], entries.get(second.Id), 2 + p));
            }
        }
        insert items;

        // An order can only be activated once it has products. Cancelled orders stay in Draft.
        List<Order> toActivate = new List<Order>();
        for (Order record : orders) {
            if (record.Fulfillment_Status__c != 'Cancelled') {
                toActivate.add(new Order(Id = record.Id, Status = 'Activated'));
            }
        }
        update toActivate;
        return byPartner;
    }

    private static OrderItem newItem(Order parent, PricebookEntry entry, Integer quantity) {
        return new OrderItem(
            OrderId = parent.Id,
            PricebookEntryId = entry.Id,
            Product2Id = entry.Product2Id,
            UnitPrice = entry.UnitPrice,
            Quantity = quantity
        );
    }

    private static List<Return_Request__c> insertReturns(
        Map<String, Account> accounts,
        Map<String, Contact> primaryContacts,
        Map<String, List<Order>> orders
    ) {
        Map<Id, Id> firstProductByOrder = new Map<Id, Id>();
        Set<Id> orderIds = new Set<Id>();
        for (List<Object> row : RETURN_ROWS) {
            orderIds.add(orders.get((String) row[0])[(Integer) row[1]].Id);
        }
        for (OrderItem item : [SELECT OrderId, Product2Id FROM OrderItem WHERE OrderId IN :orderIds ORDER BY OrderItemNumber DESC]) {
            firstProductByOrder.put(item.OrderId, item.Product2Id);
        }

        List<Return_Request__c> records = new List<Return_Request__c>();
        for (List<Object> row : RETURN_ROWS) {
            String partnerCode = (String) row[0];
            Order parent = orders.get(partnerCode)[(Integer) row[1]];
            records.add(
                new Return_Request__c(
                    Account__c = accounts.get(partnerCode).Id,
                    Order__c = parent.Id,
                    Product__c = firstProductByOrder.get(parent.Id),
                    Requested_By__c = primaryContacts.get(partnerCode).Id,
                    Quantity__c = 1,
                    Reason__c = (String) row[2],
                    Status__c = (String) row[3],
                    Resolution_Notes__c = (String) row[4],
                    Description__c = 'Demo return request created by the seed script.'
                )
            );
        }
        insert records;
        return records;
    }
}
