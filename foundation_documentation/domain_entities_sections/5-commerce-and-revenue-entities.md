## 5. Commerce and Revenue Entities

- **Catalog Item**: Atomic sellable unit (course bundle, experience, physical good, service) with media gallery and descriptive attributes. Items act as building blocks for product packaging.
- **Product Package**: Commercial bundle referencing catalog items, quantity mixes, and merchandising assets, tailored for specific audiences or channels.
- **Price Template**: Prototype defining billing cadence, payment terms, proration rules, and discount structures used to generate immutable prices.
- **Price Offer**: Concrete commercial record cloned from a template capturing currency, tiers, billing cycles, usage allowances, and activation windows. Prices act as the source of truth for sales terms.
- **Contract**: Immutable snapshot of the selected price offer coupled with buyer, account, attribution, and fulfillment metadata at the moment of sale.
- **Invoice**: Billing artifact aggregating line items, tax calculations, discounts, and payment status for a specific contract or usage period.
- **Payment Intent**: Authorization request containing payable amount, payment method references, risk signals, and compliance checks prior to capture.
- **Payment Transaction**: Settled financial movement linked to an invoice or contract, storing gateway response, settlement timestamps, and reconciliation identifiers.
- **Usage Record**: Metered event documenting consumable quantities under a contract for post-paid billing or analytics.
- **Refund**: Immutable ledger of returned funds against a payment transaction including reason codes and processing state.
- **Credit Note**: Non-cash instrument granting service credits with remaining balance tracking and issuance context.
- **Credit Note Application**: Audit trail detailing how credit notes reduce invoice balances over time.
- **Promotion Instrument**: Discount or incentive mechanism (coupon, service credit, campaign code) defining eligibility rules and redemption metrics.
- **Attribution Source**: Unified catalog of affiliates, sales representatives, campaigns, and partner programs eligible for revenue credit, including tracking codes and lifecycle status.
- **Attribution Touchpoint**: Immutable record of interactions between anonymous or authenticated actors and attribution sources, supporting commission, ROI, and funnel analysis.

---

