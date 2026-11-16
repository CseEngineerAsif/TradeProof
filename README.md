# tradeproof

TradeProof competency verification platform

## Firebase setup

Firebase is initialized with platform-specific options in
`lib/firebase_options.dart`. To regenerate the configuration after changing
Firebase projects or adding platforms, run:

```shell
flutterfire configure --project=<firebase-project-id> --platforms=web,android,ios
```

## Marketplace requests and messaging

Employer job posts, trainer courses, and tradesperson profiles are published
to Firestore with their owner's account ID. Other signed-in accounts can send
requests from the marketplace; owners can accept or decline them from
**Messages & requests**. Conversations are available only after acceptance.

Deploy the included Firestore security rules to the Firebase project before
using this workflow:

```shell
firebase deploy --only firestore:rules --project <firebase-project-id>
```

Featured sample listings are previews and are not linked to account owners.
Requests should be sent from posts published by TradeProof accounts.

## Course checkout preview

Course enrollment supports a gateway-style bKash/Nagad preview and offline
cash or bank-transfer instructions. The online flow is simulated only: it does
not contact a payment provider or charge money. Offline receipts are confirmed
by the course owner in **Messages & requests**.

To accept real payments, replace the preview with a trusted server-side
integration that creates and verifies provider transactions. Never put
merchant secrets in the Flutter app or treat a client-created payment status
as proof of payment. Existing course posts created before checkout support need
to be republished by the trainer to save a structured course fee. Deploy the
updated Firestore rules before testing checkout:

```shell
firebase deploy --only firestore:rules --project <firebase-project-id>
```
