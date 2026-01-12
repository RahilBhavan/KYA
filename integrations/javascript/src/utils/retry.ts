/**
 * Retry utility for API calls
 */

export interface RetryOptions {
  maxAttempts?: number;
  delay?: number;
  backoff?: 'linear' | 'exponential';
  retryableErrors?: string[];
}

const DEFAULT_OPTIONS: Required<RetryOptions> = {
  maxAttempts: 3,
  delay: 1000,
  backoff: 'exponential',
  retryableErrors: ['ECONNRESET', 'ETIMEDOUT', 'ENOTFOUND', 'ECONNREFUSED'],
};

/**
 * Retry a function with exponential backoff
 */
export async function retry<T>(
  fn: () => Promise<T>,
  options: RetryOptions = {}
): Promise<T> {
  const opts = { ...DEFAULT_OPTIONS, ...options };
  let lastError: Error | null = null;

  for (let attempt = 1; attempt <= opts.maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error: any) {
      lastError = error;

      // Check if error is retryable
      const isRetryable = opts.retryableErrors.some(
        (retryableError) => error.code === retryableError || error.message?.includes(retryableError)
      );

      // Don't retry on last attempt or non-retryable errors
      if (attempt === opts.maxAttempts || !isRetryable) {
        throw error;
      }

      // Calculate delay
      let delay = opts.delay;
      if (opts.backoff === 'exponential') {
        delay = opts.delay * Math.pow(2, attempt - 1);
      } else {
        delay = opts.delay * attempt;
      }

      // Wait before retry
      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }

  throw lastError || new Error('Retry failed');
}

/**
 * Retry with custom error handler
 */
export async function retryWithHandler<T>(
  fn: () => Promise<T>,
  errorHandler: (error: Error, attempt: number) => boolean,
  options: RetryOptions = {}
): Promise<T> {
  const opts = { ...DEFAULT_OPTIONS, ...options };
  let lastError: Error | null = null;

  for (let attempt = 1; attempt <= opts.maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error: any) {
      lastError = error;

      // Check if should retry
      const shouldRetry = errorHandler(error, attempt);

      if (attempt === opts.maxAttempts || !shouldRetry) {
        throw error;
      }

      // Calculate delay
      let delay = opts.delay;
      if (opts.backoff === 'exponential') {
        delay = opts.delay * Math.pow(2, attempt - 1);
      } else {
        delay = opts.delay * attempt;
      }

      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }

  throw lastError || new Error('Retry failed');
}

