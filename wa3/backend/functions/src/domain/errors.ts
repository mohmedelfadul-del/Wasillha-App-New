import type { ErrorCode } from "./contract";

/** A business-rule failure. Mapped to an HttpsError with `details.code` at the edge. */
export class DomainError extends Error {
  constructor(
    public readonly code: ErrorCode,
    message: string,
    public readonly details: Record<string, unknown> = {},
  ) {
    super(message);
    this.name = "DomainError";
  }
}

export const fail = (code: ErrorCode, message: string, details: Record<string, unknown> = {}): never => {
  throw new DomainError(code, message, details);
};
