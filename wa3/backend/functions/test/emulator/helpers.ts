import { randomBytes } from "crypto";
import { deleteApp, initializeApp as clientApp, type FirebaseApp } from "firebase/app";
import { connectAuthEmulator, getAuth as clientAuth, signInWithCustomToken } from "firebase/auth";
import { connectFirestoreEmulator, getFirestore as clientDb, type Firestore as ClientDb } from "firebase/firestore";
import { connectFunctionsEmulator, getFunctions, httpsCallable } from "firebase/functions";
import { getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";

export const PROJECT = "demo-wa3";
if (getApps().length === 0) initializeApp({ projectId: PROJECT });
export const admin = getFirestore();

export const key = () => randomBytes(12).toString("hex");
const apps: FirebaseApp[] = [];

export interface Client {
  uid: string;
  db: ClientDb;
  call: <T = any>(name: string, data?: Record<string, unknown>) => Promise<T>;
  /** Calls and returns the error code (or "ok"). */
  code: (name: string, data?: Record<string, unknown>) => Promise<string>;
}

export async function client(uid: string, opts: { phone?: string; claims?: Record<string, unknown> } = {}): Promise<Client> {
  const auth = getAuth();
  await auth.deleteUser(uid).catch(() => undefined);
  await auth.createUser({ uid, phoneNumber: opts.phone });
  if (opts.claims) await auth.setCustomUserClaims(uid, opts.claims);
  const token = await auth.createCustomToken(uid, opts.claims);
  const app = clientApp({ projectId: PROJECT, apiKey: "fake-api-key", appId: "1:1:web:1" }, `${uid}-${key()}`);
  apps.push(app);
  const a = clientAuth(app);
  connectAuthEmulator(a, "http://127.0.0.1:9099", { disableWarnings: true });
  await signInWithCustomToken(a, token);
  const db = clientDb(app);
  connectFirestoreEmulator(db, "127.0.0.1", 8080);
  const fns = getFunctions(app, "europe-west1");
  connectFunctionsEmulator(fns, "127.0.0.1", 5001);
  const call = async <T>(name: string, data: Record<string, unknown> = {}) => (await httpsCallable(fns, name)(data)).data as T;
  const code = async (name: string, data: Record<string, unknown> = {}) => {
    try { await call(name, data); return "ok"; } catch (e: any) { return e?.details?.code ?? e?.code ?? String(e); }
  };
  return { uid, db, call, code };
}

export async function closeAll() {
  await Promise.all(apps.map((a) => deleteApp(a)));
}

export async function waitFor<T>(fn: () => Promise<T | null | undefined | false>, label: string, ms = 20000): Promise<T> {
  const t0 = Date.now();
  while (Date.now() - t0 < ms) {
    const v = await fn();
    if (v) return v as T;
    await new Promise((r) => setTimeout(r, 300));
  }
  throw new Error(`timeout waiting for ${label}`);
}

export const PICKUP = { lat: 15.5776, lng: 32.5634, label: "Riyadh" };
export const DROPOFF = { lat: 15.5512, lng: 32.564, label: "Afra Mall" };
export const NEAR_PICKUP = { lat: 15.585, lng: 32.57 };

export async function seed() {
  const { KHARTOUM_ZONE, DEFAULT_PRICING } = await import("../../src/seedData");
  const { id, ...zone } = KHARTOUM_ZONE;
  await admin.collection("zones").doc(id).set(zone);
  for (const [category, c] of Object.entries(DEFAULT_PRICING)) {
    await admin.collection("pricing").doc(`${id}__${category}`).set({ zoneId: id, category, enabled: true, version: 1, ...c });
  }
}
