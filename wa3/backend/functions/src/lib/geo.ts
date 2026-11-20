import { distanceBetween, geohashForLocation, geohashQueryBounds } from "geofire-common";
import { fail } from "../domain/errors";

export interface LatLng {
  lat: number;
  lng: number;
}

export interface PlacePoint extends LatLng {
  label: string;
}

export function assertLatLng(v: unknown, what = "location"): LatLng {
  const p = v as Partial<LatLng> | null;
  if (!p || typeof p.lat !== "number" || typeof p.lng !== "number" || Math.abs(p.lat) > 90 || Math.abs(p.lng) > 180) {
    return fail("validation_failed", `A valid ${what} is required`);
  }
  return { lat: p.lat, lng: p.lng };
}

export function assertPlace(v: unknown, what: string): PlacePoint {
  const ll = assertLatLng(v, what);
  const label = String((v as { label?: unknown }).label ?? "").trim().slice(0, 140);
  return { ...ll, label: label || `${ll.lat.toFixed(5)}, ${ll.lng.toFixed(5)}` };
}

export const km = (a: LatLng, b: LatLng) => distanceBetween([a.lat, a.lng], [b.lat, b.lng]);
export const geohash = (p: LatLng) => geohashForLocation([p.lat, p.lng]);
export const geohashBounds = (p: LatLng, radiusKm: number) => geohashQueryBounds([p.lat, p.lng], radiusKm * 1000);

/** Ray-casting point-in-polygon (polygon as ordered vertices). */
export function insidePolygon(p: LatLng, poly: readonly LatLng[]): boolean {
  let inside = false;
  for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    const a = poly[i], b = poly[j];
    const crosses = (a.lat > p.lat) !== (b.lat > p.lat) &&
      p.lng < ((b.lng - a.lng) * (p.lat - a.lat)) / (b.lat - a.lat) + a.lng;
    if (crosses) inside = !inside;
  }
  return inside;
}

/** presence.updatedAt is a Firestore Timestamp (server time) — tolerate numbers from tooling. */
export function millis(v: unknown): number {
  if (typeof v === "number") return v;
  const t = v as { toMillis?: () => number } | null;
  return t && typeof t.toMillis === "function" ? t.toMillis() : 0;
}
