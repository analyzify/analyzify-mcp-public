# Shopify Store Data

All Shopify queries use `execute_graphql` with the `shopifyProxy` query. This proxies requests to the Shopify Admin GraphQL API — no separate Shopify token needed.

## Query Format

```graphql
{ shopifyProxy(query: "<shopify_graphql_query>") { data errors } }
```

With variables:
```graphql
query($vars: JSON) { shopifyProxy(query: "<shopify_query_with_variables>", variables: $vars) { data errors } }
```

## Common Queries

### List Products
```graphql
{ shopifyProxy(query: "{ products(first: 10) { edges { node { id title handle status totalInventory priceRangeV2 { maxVariantPrice { amount currencyCode } minVariantPrice { amount currencyCode } } } } pageInfo { hasNextPage endCursor } } }") { data errors } }
```

### List Collections
```graphql
{ shopifyProxy(query: "{ collections(first: 10) { edges { node { id title handle productsCount } } pageInfo { hasNextPage endCursor } } }") { data errors } }
```

### Get Shop Info
```graphql
{ shopifyProxy(query: "{ shop { name email myshopifyDomain plan { displayName } currencyCode timezoneAbbreviation } }") { data errors } }
```

### List Orders
```graphql
{ shopifyProxy(query: "{ orders(first: 10, sortKey: CREATED_AT, reverse: true) { edges { node { id name totalPriceSet { shopMoney { amount currencyCode } } createdAt displayFinancialStatus displayFulfillmentStatus } } } }") { data errors } }
```

### Search Products
```graphql
{ shopifyProxy(query: "{ products(first: 10, query: \"title:*shirt*\") { edges { node { id title handle status } } } }") { data errors } }
```

## Notes

- Uses the Shopify Admin GraphQL API — refer to Shopify docs for available queries
- Read only: queries are supported; a mutation is refused. You cannot change products, orders or anything else in the store
- Customer personal data (names, e-mails, phone numbers, addresses) comes back as `[redacted: …]` unless the API key has the `pii` capability (see `capabilities` in extMe). Say it is hidden for this key; never say the customer has no e-mail or address
- Pagination: use `pageInfo.endCursor` with `after:` argument
- The response wraps Shopify's raw response: check `data` for results, `errors` for issues
- Use `introspect_schema` and search "shopify" to see the exact type definition
