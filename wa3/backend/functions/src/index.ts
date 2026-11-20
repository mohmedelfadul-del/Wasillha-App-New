/**
 * Wasilha v1 backend — every mutation is a command here; clients only read.
 * See wa3/docs/architecture.md for the state machine and data model.
 */
export * from "./commands/rider";
export * from "./commands/driver";
export * from "./commands/trip";
export * from "./commands/ops";
export { onTripWritten, sweeper, sharedTrip } from "./triggers";
