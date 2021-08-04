---
title: "V-Token Overview"
type: "page"
date: 2021-08-03T14:39:00-06:00
subtitle: "The Key to our Blockchain Architecture"
images: ""
tags: ["v-token"]
authors: ["kylebrown", "anishleekkala"]
draft: false
---

*August, 2021*

The Vertalo V-Token is a standardized smart-contract architecture that gives private issuers flexibility in their offerings and tokenizations. Built upon a proprietary technology that Vertalo developed for its own STO in 2018, it can implement any trading-restriction policy from full lockup to free trading, *and can be upgraded at any future date to change the restrictions*.

As a regulated entity in its capacity as a licensed transfer agent, Vertalo works to ensure the movement and custodying of digital securities (using the V-Token) in a regulatory compliant manner for the benefit of our clients.

## **Role Assignment**

The V-Token uses *roles* to control administration of tokens. The following items describe the concept of *role assignment* embodied by the Vertalo V-Token:

-   When a V-Token is issued to represent an asset, different parties have different levels of control with respect to the V-Token -- in other words, various players in the market have different "roles" just as they do today.

-   Some roles are more pertinent to broker-dealer custody requirements whereas other roles make non-custodial broker-dealer models for digital asset securities approachable and safe.

-   The **owner role** retains ultimate control of the V-Token and has the ability to assign defined roles to other parties. The owner role ensures that the appropriate party has pre-defined amounts of control over the digital asset.

-   The owner can designate one or more parties as a **transfer controller** or **allowance controller**. The owner also determines what implementation the V-Token incorporates to restrict trading of the asset based on pre-defined investor eligibility, jurisdiction, limits on holder count, and other rules.

## **V-Token Architecture**

A constellation of contracts and libraries make up the V-Token, each interfacing with the others as needed to fulfill their individual responsibilities. Here is a simplified view of the smart-contract architecture:

![V-Token Architecture](/v-token-overview/v-token-architecture.png)

-   **PublicFront contract**. This contract is where all contract calls go to. It has no storage, only methods that forward to PublicLogic or Storage.

-   **PublicLogic contract**. This contract manages token specific restrictions and delegates all functions to the proper location.

-   **Roles contract**. This contract allows for the adding, removing, and verification of roles associated with the V-Token.

-   **Storage contract**. This contract manages the storage of all PublicFront contracts. It maps PublicFront contract addresses to balances and allowances.

The V-Token is *fully upgradeable* (both for tradability and controller function) at any time after initial deployment.

### Access Control

The V-Token architecture implements a fine-grained access control mechanism that enforces method-level restrictions within contracts, ensuring that control is delegated to parties in a very precise way. For example, the **transfer controller** role allows the assigned party to:

-   Move V-Tokens from one wallet to another.

-   Settle trades, handle escheatment, and rectify erroneous or unauthorized transfers.

All transfer controller activity is identifiable as such in the blockchain record, providing an audit trail. The transfer controller role resembles a traditional custodian/transfer agent/carrying broker-dealer role.

Likewise, the **allowance controller** role, allows the assigned party to:

-   Designate balances available for movement by a third party (e.g. a broker for the transfer).

-   Approve a trade between two wallets that is then settled by another party.

Again, these approvals are visible on the blockchain, providing a complete audit trail of allowance controller activity and subsequent transfers. The allowance controller resembles the role of an entity that reports transactions for settlement by another party.

*Through the use of roles to control access to method calls, the V-Token supports the division of responsibilities required by securities regulations.*
