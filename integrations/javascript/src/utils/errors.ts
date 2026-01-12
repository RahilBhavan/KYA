/**
 * Custom error classes for KYA Protocol integrations
 */

export class KYASDKError extends Error {
  constructor(message: string, public code?: string, public cause?: Error) {
    super(message);
    this.name = 'KYASDKError';
    Object.setPrototypeOf(this, KYASDKError.prototype);
  }
}

export class AxiomError extends KYASDKError {
  constructor(message: string, code?: string, cause?: Error) {
    super(message, code, cause);
    this.name = 'AxiomError';
    Object.setPrototypeOf(this, AxiomError.prototype);
  }
}

export class BrevisError extends KYASDKError {
  constructor(message: string, code?: string, cause?: Error) {
    super(message, code, cause);
    this.name = 'BrevisError';
    Object.setPrototypeOf(this, BrevisError.prototype);
  }
}

export class UMAError extends KYASDKError {
  constructor(message: string, code?: string, cause?: Error) {
    super(message, code, cause);
    this.name = 'UMAError';
    Object.setPrototypeOf(this, UMAError.prototype);
  }
}

export class KlerosError extends KYASDKError {
  constructor(message: string, code?: string, cause?: Error) {
    super(message, code, cause);
    this.name = 'KlerosError';
    Object.setPrototypeOf(this, KlerosError.prototype);
  }
}

export class EntryPointError extends KYASDKError {
  constructor(message: string, code?: string, cause?: Error) {
    super(message, code, cause);
    this.name = 'EntryPointError';
    Object.setPrototypeOf(this, EntryPointError.prototype);
  }
}

/**
 * Check if error is retryable
 */
export function isRetryableError(error: Error): boolean {
  const retryableCodes = ['ECONNRESET', 'ETIMEDOUT', 'ENOTFOUND', 'ECONNREFUSED'];
  const retryableMessages = ['timeout', 'network', 'connection'];

  if ('code' in error && retryableCodes.includes(error.code as string)) {
    return true;
  }

  if (error.message) {
    return retryableMessages.some((msg) =>
      error.message.toLowerCase().includes(msg)
    );
  }

  return false;
}

