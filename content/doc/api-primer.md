---
title: "Vertalo API Primer"
type: "page"
date: 2021-08-03T14:39:00-06:00
subtitle: "An Introduction to the Vertalo API"
images: ""
tags: ["api"]
authors: ["kylebrown", "anishleekkala"]
draft: false
---

*January, 2022*

## Table of Contents
1. [Introduction](#introduction)
2. [PostGraphile](#postgraphile)
3. [Getting Going](#getting-going)
4. [The Vertalo Object Model](#the-vertalo-object-model)
5. [Asset Creation and Configuration](#asset-creation-and-configuration)
6. [Investor Setup](#investor-setup)
7. [Primary Issuance](#primary-issuance)
8. [Making Use of Conditions and Filters](#making-use-of-conditions-and-filters)
9. [Post-Issuance Trading and Transfer](#post-issuance-trading-and-transfer)
10. [Access via API Key](#access-via-api-key)
11. [Coding Samples](#coding-samples)

## Introduction

As an "API first" company, Vertalo has designed its platform in an open and flexible way. This makes it possible for our partners to integrate with our platform through the Vertalo API when and where it's needed. This could range from pulling or pushing data for a specific purpose to a full scale implementation of a custom UI. (The Vertalo portal is, in fact, a reference application built on top of our own API.)

The key to understanding how our API operates is understanding the [GraphQL specification](spec.graphql.org/) originally conceived of by Facebook in 2012. GraphQL is now an open standard that any vendor can implement. (Click [here](https://graphql.org/code/) to see a current list of implementations.) It is very different from the traditional REST API model and the overhead that is frequently associated with having to make multiple round trips to various endpoints in order to gather the data you want. Instead, a GraphQL implementation exposes a single endpoint that can accept complex queries based on a uniform query language. It is then up to the server-side GraphQL implementation to resolve the query, fetching or writing data as directed across one or more data sources.

Vertalo has established a GraphQL schema that allows our integration partners to query information from the Vertalo platform as well as write information to the platform (known as a *mutation* in GraphQL nomenclature).

This primer is by no means exhaustive, but is meant to get you well-grounded in the basics of the Vertalo API so that you can explore further on your own.

*Recommended reading:*

- GraphQL specification: [http://spec.graphql.org](http://spec.graphql.org)

- GraphQL tutorial: [https://graphql.org/learn](https://graphql.org/learn)

### PostGraphile

The Vertalo GraphQL API is derived from a collection of PostgreSQL databases that underpin our platform. We also use an open-source framework called [PostGraphile](https://www.graphile.org/postgraphile/introduction), which is able to interpret a PostgreSQL schema and then auto-generate a GraphQL schema from it. It is recommended that you gain some familiarity with PostGraphile in order to understand how the Vertalo API is created. The PostGraphile documentation provides a roadmap to what you'll see in the Vertalo API. In particular, the following concepts are important to your understanding of how to interact with our API:

- Nodes

- Connections

- Edges

This nomenclature is borrowed from discrete mathematics and applies to graphs. This makes sense when you consider that Facebook (the creator of GraphQL) is a social graph company and, therefore, thinks of data in terms of graphs; specifically, how different entities relate to one another. GraphQL is an expression of this approach, but can actually be applied to any dataset.

*Recommended reading:*

- Introduction to PostGraphile: [https://www.graphile.org/postgraphile/introduction](https://www.graphile.org/postgraphile/introduction/)

- GraphQL Cursor Connection Specification: [https://relay.dev/graphql/connections.htm](https://relay.dev/graphql/connections.htm)

### Getting Going

Your starting point for exploring the Vertalo API is the Vertalo Sandbox. The Sandbox is a fully functioning version of our production environment and allows participants to model assets, rounds and distributions to investors in a safe and controlled manner. As an organization that is interested in leveraging the Vertalo API, the Sandbox also offers a way to explore and try out the API through an interactive interface. Follow these steps to access this environment:

1. Login to your Sandbox account (as an Issuer) at [https://sandbox.vertalo.com](https://sandbox.vertalo.com).

2. Select an issuer or broker-dealer role. (Which one is available to you will depend on how your Sandbox has been set up.)

3. Open a *new* browser tab (in the *same* browser) and go to [https://sandbox.vertalo.com/api/v2/graphiql](https://sandbox.vertalo.com/api/v2/graphiql).

You will be presented with an interactive GraphQL explorer called *GraphiQL*. Using GraphiQL, you can write and execute GraphQL queries and mutations. Most importantly, you have access to a documentation panel on the right side of the screen that exposes the *entire* GraphQL schema and Vertalo API.

![GraphiQL Overview](/api-primer/graphiql-overview.png)


- The left pane allows you to compose your query or mutation.

- The middle pane displays the results of your query or mutation

- The right pane displays the Documentation Explorer and allows you to search and navigate the Vertalo API.

To execute a query or mutation you've composed in the left pane, click the "play" button just above the left pane.

### The Vertalo Object Model

The Vertalo object model consists of the following major components:

- Users

- Accounts

- Assets

- Rounds

- Allocations

- Investors

- Distributions


As you peruse the API documentation in GraphiQL, you'll see these objects appearing in root-level fieldnames, type names, and other areas of the API. The examples below represent a good starting point for your exploration of the Vertalo API.

#### Query Assets

![Query Assets](/api-primer/query-assets.png)

In this example, the query returns a list of assets. Notice that the shape of the result (expressed as JSON) matches the shape of the query. This is an important feature of GraphQL.

#### Query Accounts

![Query Assets](/api-primer/query-accounts.png)

In this example, the query returns a list of accounts including the fields you requested (collectively known as the query's *payload*). Notice the use of arguments ("first") to refine the results of the query. In this case, only the first 3 accounts are returned. The type definition of a root field (as shown in the Documentation Explorer) will describe any arguments that the field supports.

#### Exploring the Object Hierarchy

![Query Assets](/api-primer/object-hierarchy.png)

In this example, the query traverses the Vertalo object hierarchy in order to expose detail at multiple levels. It is critical that you understand how objects relate to one another in order to drill down to the information you want to access or create. The basic object hierarchy is:

    Issuers (which manage)

        Assets (which contain)

            Rounds (which contain)

                Allocations (which contain)

                    Investors (which hold)

                        Distributions

Understanding the parent/child relationships expressed above is essential. And while you may create this hierarchy either manually using the Vertalo portal or programmatically using the API, you must ensure that parent objects exist before attempting to create related child objects. Also, you should notice how the *shape* of the resulting data matches the *shape* of the query in the above example. This is a feature of GraphQL. In the case of this example, the object hierarchy is expressed both in the query and the result.

### Asset Creation and Configuration

For first order of business in the Vertalo platform is to define and configure the assets that you wish to make available for investment to your investors. This covers a range of actions including adding a new asset, defining a round under an asset, and defining an allocation under a round.

**[Note: There may be instances where, for a particular object, you see dual mutations in the API in the form of "make\<Object\>" and "create\<Object\>". In these instances, use the "make\<Object\>" form. For example, use "makeRound" rather than "createRound".]**

#### Create an Asset
```
Request:

mutation {
  createAsset (
    input: {
      asset: {
        name: "Example Asset #1"
        type: "Preferred Equity"
        authorizedTotal: "5000000"
        status: "Active"
      }
    }
  ) {
    asset {
      id
    }
  }
}
```
```
Response:

{
  "data": {
    "createAsset": {
      "asset": {
        "id": "b29704fd-5613-4f16-b712-a942a126413b"
      }
    }
  }
}
```

In this example, the mutation creates a new asset with the required properties. It also shows a return payload requested as part of the mutation. This is a powerful feature of GraphQL which gives the developer a high degree of control over what information is returned as a result of a mutation.

#### Create a Round
```
Request:

mutation {
  makeRound (
    input: {
      assetId: "b29704fd-5613-4f16-b712-a942a126413b"
      name: "Series A"
      opensOn: "2022-01-01"
      closesOn: "2022-03-31"
      total: "2000000"
      price: "1.00"
      status: "Active"
      termsUrl: "https://dataroom.example.com"
    }
  ) {
    round {
      id
    }
  }
}
```
```
Response:

{
  "data": {
    "makeRound": {
      "round": {
        "id": "3fb91ee2-eb13-4308-b4ca-1c968a6546a4"
      }
    }
  }
}
```

In this example, the mutation creates a new round that is associated with the asset created in the previous example. It also shows a return payload requested as part of the mutation. Note that the *asset ID* returned from the previous example of the creation of an asset is used in the creation of the round; this joins the round to the asset.

#### Create an Allocation
```
Request:

mutation {
  createAllocation (
    input: {
      allocation: {
        roundId: "3fb91ee2-eb13-4308-b4ca-1c968a6546a4"
        name: "Domestic Investors"
        opensOn: "2022-01-01"
        closesOn: "2022-03-31"
      }
    }
  ) {
    allocation {
      id
    }
  }
}
```
```
Response:

{
  "data": {
    "createAllocation": {
      "allocation": {
        "id": "abb668d2-63d2-43dd-b495-b1e413a69427"
      }
    }
  }
}
```

An *allocation* is a grouping of distributions within a round that allows the issuer to distinguish groups of investors within a round, for example, domestic vs other.

In this example, the mutation creates a new allocation (a grouping of investment under a round) that is associated with the round created in the previous example. It also shows a return payload requested as part of the mutation. Note that the *round ID* returned from the previous example of the creation of a round is used in the creation of the allocation; this joins the allocation to the round.

### Investor Setup

Adding investors to the platform requires that you supply some basic information. The investor's email address acts as a *primary key*.

#### Create an Investor
```
Request:

mutation {
  makeCustomer (
    input: {
      name: "Bob Smith"
      _email: "bob.smith@example.com"
    }
  ) {
    customer {
      id
      investorId
    }
  }
}
```
```
Response:

{
  "data": {
    "makeCustomer": {
      "customer": {
        "id": "09aeaea6-e3f9-49cd-8a91-898ea18aa8b8",
        "investorId": "d6fb328d-2426-4689-98d0-8a0a03679a03"
      }
    }
  }
}
```

In this example, the mutation creates a new customer and corresponding investor account. At this point the investor is *not* associated with any investment opportunity on the platform.

### Primary Issuance

The process of formally issuing securities to investors through the Vertalo platform involves a series of actions which offer a tremendous amount of flexibility.

#### Create a Distribution

A *distribution* is an initial assignment of a quantity of units (typically shares) to an investor within an allocation.
```
Request:

mutation {
  makeDistribution (
    input: {
      _allocationId: "abb668d2-63d2-43dd-b495-b1e413a69427"
      accountEmail: "bob.smith@example.com"
      amount: "100000"
    }
  ) {
    distribution {
      id
      status
    }
  }
}
```
```
Response:

{
  "data": {
    "makeDistribution": {
      "distribution": {
        "id": "8f444de2-bfd9-4ca5-b6f4-74c4e511cebc",
        "status": "drafted"
      }
    }
  }
}
```

In this example, the mutation creates a new distribution that is associated with an allocation. It also shows a return payload requested as part of the mutation. Note that the *allocation ID* returned from the previous example of the creation of an allocation is used in the creation of the distribution; this joins the distribution to the allocation.

The value of the *status* field in the previous response indicates that the distribution was successfully created and placed into a "drafted" state. This is now a *pro forma* entry on a cap table for the corresponding allocation, *but the distribution will not yet appear in the investor's portfolio in the Vertalo investor portal.* When appropriate, you may update the status of the distribution to "open" (investor qualifications met, waiting for funding) or "closed" (funding has been received, available for issuance), either of which will make the distribution visible to the investor in the Vertalo portal.

#### Update a Distribution

When a distribution is initially created for an investor the status of the distribution is set to "drafted", indicating that this is a pro forma distribution that the issuer will approve in order to allow the investor to proceed through the investment process. This will typically involve the investor completing qualification requirements (KYC/AML, for instance), signing documents, and providing payment. While in a drafted state, the distribution *will not* appear in the investor's portfolio view within the Vertalo portal (though it could appear in your custom investor UI if you choose). When appropriate, the distribution may be updated to "open" (to allow the investor to commence the investment process) or "closed" (to indicate that the investor has provided all necessary documents and payment). This can be done via the API as follows:
```
Request:

mutation {
  updateDistributionById (
    input: {
      id: "8f444de2-bfd9-4ca5-b6f4-74c4e511cebc"
      distributionPatch: {status: "closed"}
    }
  ) {
    distribution {
      id
      status
    }
  }
}
```
```
Response:

{
  "data": {
    "updateDistributionById": {
      "distribution": {
        "id": "8f444de2-bfd9-4ca5-b6f4-74c4e511cebc",
        "status": "closed"
      }
    }
  }
}
```

The above example shows how we have "patched" a distribution to update the status from "drafted" to "closed".

#### Create a Holding
```
Request:

mutation {
  issueDistributions (
    input: {
      distributionIds: [
        "8f444de2-bfd9-4ca5-b6f4-74c4e511cebc"
      ]
    }
  ) {
    issuanceEvents {
      holdingId
    }
  }
}
```
```
Response:

{
  "data": {
    "issueDistributions": {
      "issuanceEvents": [
        {
          "holdingId": "67ebd6a5-3ffa-4336-b683-31d1d4251a2c"
        }
      ]
    }
  }
}
```

In this example, the mutation formally issues shares to the investor based on a distribution ID to create a *holding*. This transition from *distribution* to *holding* effectively locks the shares and binds them to the investor. Note that the *distribution ID* returned from the previous example of the creation of a distribution is used in the creation of the holding.

**[Important! Only distributions that are closed may be converted to holdings.]**


### Making Use of Conditions and Filters

In previous examples, you will have noticed the use of the *condition* keyword at various points in the query, which provides a rudimentary means to filter for specific values. The Vertalo API also supports the *filter* keyword, which provides even more advanced capabilities.
```
Request:

query {
  allAccounts (condition: {type: "investor", email: "bob.smith@example.com"}) {
    nodes {
      id
      name
      email
      distributionsByInvestorId {
        nodes {
          amount
          allocationByAllocationId {
            name
            roundByRoundId {
              name
              assetByAssetId {
                name
              }
            }
          }
        }
      }
    }
  }
}
```
```
Response:

{
  "data": {
    "allAccounts": {
      "nodes": [
        {
          "id": "d6fb328d-2426-4689-98d0-8a0a03679a03",
          "name": "Bob Smith",
          "email": "bob.smith@example.com",
          "distributionsByInvestorId": {
            "nodes": [
              {
                "amount": "100000.000000000000000000",
                "allocationByAllocationId": {
                  "name": "Domestic Investors",
                  "roundByRoundId": {
                    "name": "Series A",
                    "assetByAssetId": {
                      "name": "Example Asset #1"
                    }
                  }
                }
              }
            ]
          }
        }
      ]
    }
  }
}
```

*Filters* allow for more complex comparisons, and support the use of operators such as:

-   greaterThan

-   lessThan

-   equalTo

-   notEqualTo

-   isNull

...plus many other capabilities.

Please refer to the documentation found in Vertalo's GraphiQL API explorer for details on how to make use of conditions and filters.

### Post-Issuance Trading and Transfer

*This section is still under development and will be updated periodically. The sample GraphQL mutations and queries should be considered "pre-release" and subject to change.*

ATS/Exchange integrations are standardized through an API derived from the Vertalo GraphQL schema. Because of the high compliance requirements/costs associated with post-issuance trading and transfer, the goal of the Vertalo API is designed to make it as easy as possible to convey data between systems in order to maximize consistency. While the Vertalo platform uses a transaction-based architecture under the hood, we do not currently expose this to the API user and translate trading and transfer calls to transactions as needed. (Future releases may expose low-level transaction calls.)

API calls are ordered, and will be preserved and executed in the order in which they are received. The platform will take instructions typically without regard to the state in which the system may be left. For example, a transfer could result in a securities balance for an investor going below zero. Because of the asynchronous nature of transactions, this state will be allowed (though a warning will be issued).

#### trade
```
This allows you to fully construct a trade between a "from" account and a "to" account:

mutation {
    trade({
        securityId: "f133b5d8-b24a-483c-88e4-a9d7913cadf9",     //REQUIRED
        from: {                                                 //REQUIRED
            account: {                                          //REQUIRED
                id: "ac65eec2-a065-4777-ae0d-f2192fb6a164"      //REQUIRED
            }
            holdings: [{                                        //REQUIRED
                id: "44588593-2626-4380-897e-f1c4935d0d76",     //REQUIRED
                amount: "2.00"                                  //REQUIRED
            }]
        },
        fee: {                                                  //SHOULD BE PROVIDED
            currency: "USD",                                    //REQUIRED IF PRESENT
            amount: "200.00"                                    //REQUIRED IF PRESENT
        },
        price: [{                                               //OBSOLETE, PLEASE USE usdPrice and tradePrice
            currency: "USD",                                    //OBSOLETE
            amount: "20.00"                                     //OBSOLETE
        }],
        usdPrice: {
            amount: "20.00"                                     //SHOULD BE PROVIDED
        },
        tradePrice: {                                           //SHOULD BE PROVIDED
            currency: "USD",                                    //REQUIRED IF PRESENT
            amount: "20.00"                                     //REQUIRED IF PRESENT
        },
        to: {                                                   //REQUIRED
            account: {                                          //REQUIRED                                   
                id: "7a729360-f39f-49a2-894f-2727a8803b47",     //NOT AVAILABLE FOR NEW INVESTOR, SHOULD BE USED FOR EXISTING INVESTORS
                email: "newinvestortwo@example.com"             //REQUIRED FOR NEW INVESTOR (will be created), SHOULD NOT BE USED FOR EXISTING
            }
        },
        tags: [{                                                //OPTIONAL
            id: "my-tag-for-07/25/2021",                        //REQUIRED IF PRESENT
            data: {}                                            //OPTIONAL
        }],
        data: {},                                               //OPTIONAL
        matchedOn: "2021-07-28T20:09:28.951Z",                  //OPTIONAL
        settledOn: "2021-07-28T20:09:30.951Z",                  //REQUIRED
    }) {
    trade {
      id
      data
      transfersByTradeId {
        nodes {
          id
          securityBySecurityId {
            id
          }
          holdingByFromHoldingId {
            id
            amount
          }
        }
      }
    }
  }
}
```


**Trade Fields**

| Path                   | type                      | Usage                                                                               | Required                                          |
|------------------------|---------------------------|-------------------------------------------------------------------------------------|---------------------------------------------------|
| securityId             | UUID                      | Used to identify the security                                                       | REQUIRED                                          |
| from                   | Object                    | Used to convey a trades from data                                                   | REQUIRED                                          |
| from.account           | Object                    | Used to convey a transfers from account data                                        | REQUIRED                                          |
| from.account.id        | UUID                      | Used to identify the from account                                                   | REQUIRED                                          |
| from.holdings          | Array                     | Used to convey the from holdings data                                               | REQUIRED                                          |
| from.holdings[].id     | UUID                      | Used to identify the from holdings                                                  | REQUIRED                                          |
| from.holdings[].amount | Number as String          | The amount being transferred out of the holdings                                    | REQUIRED, NON ZERO, NON NEGATIVE                  |
| fee                    | Object                    | Used to convey any trading fee that is associated with the trade                    | SHOULD BE PROVIDED                                |
| fee.currency           | Currency code as String   | The currency the fee is in                                                          | REQUIRED if fee is present                        |
| fee.amount             | Number as String          | The fee amount                                                                      | REQUIRED if fee is present                        |
| price                  | Array                     | Used to convey price paid data (total price not price per share)                    | OBSOLETE                                          |
| price[].currency       | Currency alpha3 as String | The currency the price is in                                                        | OBSOLETE                                          |
| price[].amount         | Number as String          | The amount paid                                                                     | OBSOLETE                                          |
| usdPrice               | Object                    | Used to convey the trade's USD price per unit                                       | SHOULD BE PROVIDED                                |
| usdPrice.amount        | Number as String          | The amount per unit in USD                                                          | REQUIRED if usdPrice is present                   |
| tradePrice             | Currency alpha3 as String | The price paid in the currency it was paid in for the trade                         | SHOULD BE PROVIDED                                |
| tradePrice.currency    | Currency alpha3 as String | The currency the price is in                                                        | REQUIRED if tradePrice is present                 |
| tradePrice.amount      | Number as String          | The price per unit paid                                                             | REQUIRED if tradePrice is present                 |
| to                     | Object                    | Used to convey a trade's to data                                                    | REQUIRED                                          |
| to.account             | Object                    | Used to convey a transfer's to account data                                         | REQUIRED                                          |
| to.account.id          | UUID                      | Used to identify the from account, both id and email cannot be present              | SHOULD BE used when using a pre-existing account  |
| to.account.email       | String                    | Used for the creation of a new investor account                                     | MUST BE used when the to user is new to Vertalo   |
| to.account.name        | String                    | Used for the creation of a new investor account                                     | MUST BE used when the to user is new to Vertalo   |
| to.account.jurisdiction| Country Alpha3 String     | Used for the creation of a new investor account                                     | MUST BE used when the to user is new to Vertalo   |
| tags                   | Array                     | Used for associating tags with the trade or transfers                               | OPTIONAL                                          |
| tags[].id              | String                    | Used to identify the tag                                                            | REQUIRED if tags is present                       |
| tags[].data            | Object                    | Extra data to be stored with the tag                                                | OPTIONAL                                          |
| data                   | Object                    | Any extra data to be included with the trade as a whole                             | OPTIONAL                                          |
| matchedOn              | Timestamp as String       | Used to convey the trade's match time                                               | OPTIONAL                                          |
| settledOn              | Timestamp as String       | Used to convey the trade's settlement time                                          | REQUIRED                                          |


*settledOn* will be used to populate the issuedOn field in the created holding.

*usdPrice* will be used to populate purchase_price and purchase_currency in the created holdings. It is pinned to USD so that an apples to apples comparison can be made.

*tradePrice* is recorded for the investor's benefit. We do not do cryptocurrency to USD conversions, so this field is only to inform the issuer what the investor actually paid in, not the value of the trade.

#### allSecurities

This allows you to fetch all securities (and respective holdings) for which you are the listing ATS.
```
Request:

query {
  allSecurities {
    nodes {
      id
      holdingsBySecurityId {
        nodes {
          id
          investorId
          amount
          createdOn
          accountByInvestorId {
            id
            name
            email
          }
        }
      }
    }
  }
}
```
```
Response:

{
  "data": {
    "allSecurities": {
      "nodes": [
        {
          "id": "6a93a168-31b6-4a67-b9f9-8cda51e5e6ba",
          "holdingsBySecurityId": {
            "nodes": [
              {
                "id": "67ebd6a5-3ffa-4336-b683-31d1d4251a2c",
                "investorId": "d6fb328d-2426-4689-98d0-8a0a03679a03",
                "amount": "100000.000000000000000000",
                "createdOn": "2021-12-16T22:05:46.253555+00:00",
                "accountByInvestorId": {
                  "id": "d6fb328d-2426-4689-98d0-8a0a03679a03",
                  "name": "Bob Smith",
                  "email": "bob.smith@example.com"
                }
              }
            ]
          }
        }
      ]
    }
  }
}
```

#### securityById

This allows you to query an individual security (and respective holdings) by its ID.
```
Request:

query {
  securityById(id: "6a93a168-31b6-4a67-b9f9-8cda51e5e6ba") {
    id
    holdingsBySecurityId {
      nodes {
        id
        investorId
        amount
        createdOn
        accountByInvestorId {
          id
          name
          email
        }
      }
    }
  }
}
```
```
Response:

{
  "data": {
    "securityById": {
      "id": "6a93a168-31b6-4a67-b9f9-8cda51e5e6ba",
      "holdingsBySecurityId": {
        "nodes": [
          {
            "id": "67ebd6a5-3ffa-4336-b683-31d1d4251a2c",
            "investorId": "d6fb328d-2426-4689-98d0-8a0a03679a03",
            "amount": "100000.000000000000000000",
            "createdOn": "2021-12-16T22:05:46.253555+00:00",
            "accountByInvestorId": {
              "id": "d6fb328d-2426-4689-98d0-8a0a03679a03",
              "name": "Bob Smith",
              "email": "bob.smith@example.com"
            }
          }
        ]
      }
    }
  }
}
```

#### holdingsByInvestorId

This allows you to drill down into a specific investor's holdings (with an optional filter for only holdings that are greater than zero).
```
Request:

query {
  accountByTypeAndEmail(type: "investor", email: "bob.smith@example.com") {
    holdingsByInvestorId(filter: {amount: {greaterThan: "0"}}) {
      nodes {
        id
        securityId
        amount
        createdOn
      }
    }
  }
}
```
```
Response:

{
  "data": {
    "accountByTypeAndEmail": {
      "holdingsByInvestorId": {
        "nodes": [
          {
            "id": "67ebd6a5-3ffa-4336-b683-31d1d4251a2c",
            "securityId": "6a93a168-31b6-4a67-b9f9-8cda51e5e6ba",
            "amount": "100000.000000000000000000",
            "createdOn": "2021-12-16T22:05:46.253555+00:00"
          }
        ]
      }
    }
  }
}
```

### Access via API Key

Vertalo will issue clients testing and production API credentials (a client ID and client secret) for server-side programmatic access to their account(s). The process of using the credentials to claim the required access tokens and issue queries to the Vertalo API is described below. We strongly encourage you to use your regular login credentials to make use of Vertalo's interactive *GraphiQL interface* (described in detail above in this document), in addition to your testing API credentials, to test your queries in your sandbox environment before implementing them in production. Tokens you receive from the Vertalo API endpoints have an expiration time of 60 minutes, after which you will receive HTTP 401 errors. You will need to manage your use of tokens to account for expiration and request new tokens as needed.

*Please be sure to guard your Vertalo-provided credentials carefully in order to prevent inadvertent or malicious activity that could negatively affect your account.*

*Your ability to leverage the different capabilities exposed through the Vertalo API will vary depending on the rights granted to your API credentials. Not all services will be available.*

#### /authenticate/token/login

Once you've been issued a client ID and client secret, you will be able to generate a bearer token which you will then use to associate your access with a specific role that has been configured for your account.

Request:
```
curl 'https://sandbox.vertalo.com/authenticate/token/login?client_id=<client ID>&client_secret=<client secret>'
```

Response:
```
{
    "token": {
        "token_type": "Bearer",
        "access_token": "<token>"
    },
    "roles": {
        "data": [
            {
                "last_name": "example",
                "user_role": "account_admin",
                "account_type": "broker",
                "account_name": "Example",
                "user_id": "<UUID>",
                "users_account_id": "<UUID>",
                "first_name": "admin",
                "account_id": "<UUID>",
                "slug": "example",
                "email": "admin@example.vertalo.com"
            }
        ]
    }
}
```

#### /authenticate/token/role

The */token/role* endpoint allows you to select a role from a collection of available roles configured for your account. You will assume the rights of the chosen role when performing actions via the API. Using the response from the */token/login* endpoint, use the values of the *access_token* and *users_account_id* fields to construct a request to the */token/role* endpoint:

Request:
```
curl -H 'Authorization: Bearer <access_token>' 'https://sandbox.vertalo.com/authenticate/token/role/<users_account_id\>'
```

Response:
```
{
    "token": {
        "token_type": "Bearer",
        "access_token": "<token>"
    }
}
```

#### /token/api/v2/graphql

Using the response from the */token/role* endpoint, use the value of the *access_token* field to construct a request to the */token/api/v2/graphql* endpoint in which you issue a properly formed GraphQL query to the Vertalo API.

Request:
```
curl --location --request POST 'https://sandbox.vertalo.com/token/api/v2/graphql' --header 'Authorization: Bearer <access_token>' --header 'Content-Type: application/json' --data-raw '{"query": "query {\n allAssets {\n nodes {\n name\n type\n status\n authorizedTotal\n}\n}\n}", "variables":{}}'
```

Response:

```
{
    "data": {
        "allAssets": {
            "nodes": [{
                "name": "Example Preferred Equity",
                "type": "Preferred Equity",
                "status": "active",
                "authorizedTotal": "5000000"
            }]
        }
    }
}
```

### Further Support

If you require further support in your exploration of the Vertalo API, please contact Vertalo at [integrations\@vertalo.com](mailto:integrations@vertalo.com).

### Coding Samples

These coding examples are meant to provide you with guidance on how to program the process of authenticating and authorizing with the Vertalo platform via the API, and show examples of how to submit queries to the Vertalo GraphQL endpoint. You will need to request your API credentials from Vertalo before you can access the API.

#### PHP

*[This example makes use of the cURL extension for PHP. This extension must be enabled in your PHP configuration to use it.]*

```
<?php

    $ch = curl_init();

    curl_setopt($ch, CURLOPT_URL,  "https://www.sandbox.vertalo.com/authenticate/token/discovery");
    curl_exec($ch);
    curl_close($ch);

    //
    // Get LOGIN access token...
    //
    $client_id = "<your client ID>"
    $client_secret = "<your client secret>"
    curl_setopt($ch, CURLOPT_URL, "https://www.sandbox.vertalo.com/authenticate/token/login?client_id=$client_id&client_secret=$client_secret");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $response = curl_exec($ch);
    $response = json_decode($response, true);
    $access_token = $response["token"]["access_token"];
    $users_account_id = $response["roles"]["data"][0]["users_account_id"];
    print("$access_token\n");
    print("$users_account_id\n");

    //
    // Get ROLE access token...
    //
    if ($access_token && $users_account_id) {
        $headers = array();
        $headers[] = "Authorization: Bearer $access_token";
        curl_setopt($ch, CURLOPT_URL, "https://www.sandbox.vertalo.com/authenticate/token/role/$users_account_id");
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        $response = curl_exec($ch);

        $response = json_decode($response, true);
        $access_token = $response["token"]["access_token"];
        print("$access_token\n");

        //
        // Execute GraphQL query...
        //
        if ($access_token) {
        $headers = array();
        $headers[] = "Authorization: Bearer $access_token";
        $headers[] = "Content-Type: application/json; charset=utf-8";
        $query = '{"query": ' .
        '"query {' .
            'allAccounts(condition: {type: "issuer"}) {'.
                'nodes {' .
                    'name '
                    'id ' .
                    'assetsByIssuerId(condition: {name: "API Test"}) {' .
                        'nodes {' .
                            'name ' .
                            'id ' .
                            'roundsByAssetId {' .
                                'nodes {' .
                                    'name ' .
                                    'id ' .
                                    'allocationsByRoundId {' .
                                        'nodes {' .
                                            'name ' .
                                            'id ' .
                                        '}' .
                                    '}' .
                                '}' .
                            '}' .
                        '}' .
                    '}' .
                '}' .
            '}' .
        '}"' .
    '}';

    curl_setopt($ch, CURLOPT_URL, "https://www.sandbox.vertalo.com/token/api/v2/graphql");
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $query);
    $response = curl_exec($ch);

    $response = json_decode($response, true);
    var_dump($response);

   }
 }
 curl_close($ch);

?>
```

#### Python

*[This example makes use of an open-source GraphQL client module for Python, **gql**. You must first install this module into your Python environment to use it.]*

```
import requests
import json
#
# Import from GraphQL client library for Python...
#
from gql import gql, Client, AIOHTTPTransport

#
# Call token discovery endpoint...
#
response = requests.get("https://www.sandbox.vertalo.com/authenticate/token/discovery")
print(response.text)

#
# Get LOGIN access token...
#
**client_id = "<your client ID>"**
**client_secret = "<your client secret>"**
response = requests.get(f"https://www.sandbox.vertalo.com/authenticate/token/login?client_id={client_id}&client_secret={client_secret}")

response = json.loads(response.text)
access_token = response["token"]["access_token"]
users_account_id = response["roles"]["data"][0]["users_account_id"]
print(access_token)
print(users_account_id)

#
# Get ROLE access token...
#

if access_token and users_account_id:
    headers = {"Authorization": f"Bearer {access_token}"}
    response = requests.post(f"https://www.sandbox.vertalo.com/authenticate/token/role/{users_account_id}", headers=headers)

    #
    # Parse response and grab key values...
    #
    response = json.loads(response.text)
    access_token = response["token"]["access_token"]
    print(access_token)

    #
    # Execute GraphQL query...
    #
    if access_token:
        url = "https://www.sandbox.vertalo.com/token/api/v2/graphql"
        headers = {"Authorization": f"Bearer {access_token}", "Content-Type": "application/json; charset=utf-8"}
        transport = AIOHTTPTransport(url=url, headers=headers)
        client = Client(transport=transport)
        query = gql("""
            query {
                allAccounts(condition: {type: "issuer"}) {
                    nodes {
                        name
                        assetsByIssuerId(condition: {name: "API Test"}) {
                            nodes {
                                name
                                roundsByAssetId {
                                    nodes {
                                        name
                                        allocationsByRoundId {
                                            nodes {
                                                id
                                                name
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            """
        )

        response = client.execute(query)
        print(response)
```
