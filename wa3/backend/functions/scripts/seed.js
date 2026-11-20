// Environment setup with the Admin SDK (uses GOOGLE_APPLICATION_CREDENTIALS or the emulator).
//   node scripts/seed.js                       seed zone + pricing (existing docs are KEPT)
//   node scripts/seed.js --force               overwrite zone + pricing with defaults
//   node scripts/seed.js --staff <email> <role> [--create]
//        grant a staff role by email; --create makes the account (random password)
//        and sends a password-reset email so the person sets their own password.
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { randomBytes } = require("crypto");
const { KHARTOUM_ZONE, DEFAULT_PRICING } = require("../lib/seedData");

const projectId = process.env.GCLOUD_PROJECT || process.env.FIREBASE_PROJECT || "demo-wa3";
initializeApp({ projectId });
const db = getFirestore();
const ROLES = ["admin", "operations", "kyc", "support", "finance"];

async function seed(force) {
  const { id, ...zone } = KHARTOUM_ZONE;
  const zref = db.collection("zones").doc(id);
  if (force || !(await zref.get()).exists) { await zref.set(zone); console.log(`zone ${id}: written`); }
  else console.log(`zone ${id}: exists, kept`);
  for (const [category, c] of Object.entries(DEFAULT_PRICING)) {
    const ref = db.collection("pricing").doc(`${id}__${category}`);
    if (!force && (await ref.get()).exists) { console.log(`pricing ${category}: exists, kept`); continue; }
    await ref.set({ zoneId: id, category, enabled: true, version: 1, ...c, updatedBy: "seed", updatedAt: Date.now() });
    console.log(`pricing ${category}: written`);
  }
}

async function sendReset(email) {
  // Identity Toolkit REST: Firebase emails the reset link to the person (nothing is logged here).
  const key = process.env.FIREBASE_WEB_API_KEY;
  if (!key) { console.log("No FIREBASE_WEB_API_KEY; use 'Forgot password' on the console sign-in page."); return; }
  const res = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=${key}`, {
    method: "POST", headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ requestType: "PASSWORD_RESET", email }),
  });
  console.log(res.ok ? `Password-setup email sent to ${email}.` : `Could not send the email (${res.status}).`);
}

async function staff(email, role, create) {
  if (!ROLES.includes(role)) throw new Error(`role must be one of ${ROLES.join(", ")}`);
  const auth = getAuth();
  let user = await auth.getUserByEmail(email).catch(() => null);
  if (!user && create) {
    user = await auth.createUser({ email, password: randomBytes(24).toString("base64url"), emailVerified: false });
    console.log(`Created staff account for ${email}.`);
    await sendReset(email);
  }
  if (!user) throw new Error(`No account for ${email}. Re-run with --create, or add the user in Firebase Console → Authentication.`);
  await auth.setCustomUserClaims(user.uid, { staff: true, role });
  await db.collection("staff").doc(user.uid).set({ email, role, active: true, updatedAt: Date.now() }, { merge: true });
  console.log(`Granted ${role} to ${email}. They enrol an authenticator (TOTP) on first console sign-in.`);
}

(async () => {
  const a = process.argv.slice(2);
  if (a[0] === "--staff") await staff(a[1], a[2], a.includes("--create"));
  else await seed(a.includes("--force"));
})().catch((e) => { console.error(e.message); process.exit(1); });
