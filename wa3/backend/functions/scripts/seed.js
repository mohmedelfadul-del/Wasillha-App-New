// Seeds the operating zone and default pricing, and optionally a staff user.
//   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node scripts/seed.js            (emulator)
//   GOOGLE_APPLICATION_CREDENTIALS=sa.json node scripts/seed.js           (staging)
//   node scripts/seed.js --staff <uid> <role>                             (grant staff role)
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { KHARTOUM_ZONE, DEFAULT_PRICING } = require("../lib/seedData");

initializeApp({ projectId: process.env.GCLOUD_PROJECT || "demo-wa3" });
const db = getFirestore();

(async () => {
  const args = process.argv.slice(2);
  if (args[0] === "--staff") {
    const [uid, role] = args.slice(1);
    await getAuth().setCustomUserClaims(uid, { staff: true, role });
    await db.collection("staff").doc(uid).set({ role, active: true, updatedAt: Date.now() }, { merge: true });
    console.log(`Granted ${role} to ${uid}. They must enroll TOTP on first console sign-in.`);
    return;
  }
  const { id, ...zone } = KHARTOUM_ZONE;
  await db.collection("zones").doc(id).set(zone);
  for (const [category, c] of Object.entries(DEFAULT_PRICING)) {
    await db.collection("pricing").doc(`${id}__${category}`).set({ zoneId: id, category, enabled: true, version: 1, ...c, updatedBy: "seed", updatedAt: Date.now() });
  }
  console.log("Seeded zone and pricing.");
})();
