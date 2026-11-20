import type { Category } from "./domain/contract";
import type { PricingConfig } from "./domain/pricing";

/**
 * Starting data for a new environment. ASSUMPTIONS — tune in the operations
 * console before launch; these are placeholders, not researched prices.
 */
export const KHARTOUM_ZONE = {
  id: "khartoum",
  name: "Khartoum · الخرطوم",
  active: true,
  // Rough polygon around Khartoum, Omdurman and Bahri.
  polygon: [
    { lat: 15.78, lng: 32.40 },
    { lat: 15.78, lng: 32.66 },
    { lat: 15.42, lng: 32.70 },
    { lat: 15.42, lng: 32.40 },
  ],
};

export const DEFAULT_PRICING: Record<Category, PricingConfig> = {
  rickshaw: { baseFare: 500, perKm: 250, perMinute: 15, minFare: 700, maxFare: 30000, belowReferencePct: 0.2, aboveReferencePct: 1.0, commissionBps: 1000 },
  motorbike: { baseFare: 400, perKm: 200, perMinute: 10, minFare: 600, maxFare: 25000, belowReferencePct: 0.2, aboveReferencePct: 1.0, commissionBps: 1000 },
  economy: { baseFare: 1000, perKm: 350, perMinute: 25, minFare: 1500, maxFare: 60000, belowReferencePct: 0.2, aboveReferencePct: 1.0, commissionBps: 1500 },
  comfort: { baseFare: 1500, perKm: 450, perMinute: 35, minFare: 2500, maxFare: 80000, belowReferencePct: 0.15, aboveReferencePct: 1.0, commissionBps: 1500 },
  family: { baseFare: 2000, perKm: 550, perMinute: 40, minFare: 3000, maxFare: 100000, belowReferencePct: 0.15, aboveReferencePct: 1.0, commissionBps: 1500 },
};
