import { logger } from "firebase-functions";
import { fail } from "../domain/errors";
import { km, type LatLng } from "./geo";

/**
 * Server-side proxy for Google Maps Platform. The key never ships in a client.
 * MAPS_FAKE=true (emulator / local dev only) replaces Google with a
 * straight-line estimate so the trip loop can be exercised offline.
 */
const KEY = process.env.GOOGLE_MAPS_SERVER_KEY ?? "";
const FAKE = process.env.MAPS_FAKE === "true";

export interface Route {
  distanceMeters: number;
  durationSeconds: number;
  polyline: string | null;
  source: "google" | "estimate";
}

export interface PlaceResult {
  placeId: string;
  label: string;
  address: string;
  lat: number;
  lng: number;
}

async function post(url: string, fieldMask: string, body: unknown): Promise<any> {
  if (!KEY) return fail("maps_unavailable", "Maps are not configured on the server");
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-Goog-Api-Key": KEY, "X-Goog-FieldMask": fieldMask },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(8000),
  }).catch((e) => {
    logger.warn("maps request failed", e);
    return null;
  });
  if (!res || !res.ok) {
    logger.warn("maps non-200", { status: res?.status });
    return fail("maps_unavailable", "The maps service is unavailable right now. Please try again.");
  }
  return res.json();
}

export async function route(from: LatLng, to: LatLng): Promise<Route> {
  if (FAKE) {
    const meters = Math.round(km(from, to) * 1000 * 1.3);
    return { distanceMeters: meters, durationSeconds: Math.round(meters / (25_000 / 3600)), polyline: null, source: "estimate" };
  }
  const j = await post("https://routes.googleapis.com/directions/v2:computeRoutes",
    "routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline", {
      origin: { location: { latLng: { latitude: from.lat, longitude: from.lng } } },
      destination: { location: { latLng: { latitude: to.lat, longitude: to.lng } } },
      travelMode: "DRIVE",
      routingPreference: "TRAFFIC_AWARE",
    });
  const r = j?.routes?.[0];
  if (!r) return fail("maps_unavailable", "No drivable route found between these points");
  return {
    distanceMeters: Number(r.distanceMeters ?? 0),
    durationSeconds: parseInt(String(r.duration ?? "0s"), 10),
    polyline: r.polyline?.encodedPolyline ?? null,
    source: "google",
  };
}

export async function searchPlaces(query: string, near: LatLng, lang: string): Promise<PlaceResult[]> {
  if (FAKE) return [];
  const j = await post("https://places.googleapis.com/v1/places:searchText",
    "places.id,places.displayName,places.formattedAddress,places.location", {
      textQuery: query,
      languageCode: lang === "ar" ? "ar" : "en",
      regionCode: "SD",
      maxResultCount: 8,
      locationBias: { circle: { center: { latitude: near.lat, longitude: near.lng }, radius: 30000 } },
    });
  return ((j?.places ?? []) as any[]).filter((p) => p.location).map((p) => ({
    placeId: String(p.id),
    label: String(p.displayName?.text ?? ""),
    address: String(p.formattedAddress ?? ""),
    lat: Number(p.location.latitude),
    lng: Number(p.location.longitude),
  }));
}

/** Human label for a map-picked point (reverse geocoding). */
export async function labelFor(p: LatLng, lang: string): Promise<string> {
  if (FAKE || !KEY) return `${p.lat.toFixed(5)}, ${p.lng.toFixed(5)}`;
  const url = `https://maps.googleapis.com/maps/api/geocode/json?latlng=${p.lat},${p.lng}&language=${lang === "ar" ? "ar" : "en"}&key=${KEY}`;
  const res = await fetch(url, { signal: AbortSignal.timeout(8000) }).catch(() => null);
  const j: any = res && res.ok ? await res.json() : null;
  return String(j?.results?.[0]?.formatted_address ?? `${p.lat.toFixed(5)}, ${p.lng.toFixed(5)}`);
}
