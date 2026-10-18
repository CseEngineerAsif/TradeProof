// OPTIONAL (needs Firebase Blaze plan). Re-computes the credential seal on the
// server so a client cannot forge it. Same formula as credHash() in the app.
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
const crypto = require('crypto');
admin.initializeApp();

exports.sealCredential = onDocumentCreated('credentials/{id}', async (event) => {
  const d = event.data.data();
  const hash = crypto.createHash('sha256')
    .update([d.name, d.holder, d.issuer, d.date].join('|'))
    .digest('hex');
  return event.data.ref.update({ serverHash: hash, sealed: hash === d.hash });
});
