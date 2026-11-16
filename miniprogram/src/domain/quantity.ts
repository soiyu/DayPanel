/**
 * Quantity values are integer thousandths. Input and persisted values never
 * use floating point; "1.5" is 1500. Zero is a real record and is distinct
 * from "not recorded" (null).
 */

const QUANTITY_RE = /^\d{1,9}(\.\d{1,3})?$/;
const COUNT_RE = /^\d{1,9}$/;

export function parseQuantity(input: string): number | null {
  const normalized = input.trim().replaceAll('，', '.').replaceAll(',', '.');
  if (!QUANTITY_RE.test(normalized)) return null;
  const [whole, fraction = ''] = normalized.split('.');
  const value = Number(whole) * 1000 + Number(fraction.padEnd(3, '0'));
  return Number.isSafeInteger(value) ? value : null;
}

export function parseCount(input: string): number | null {
  const normalized = input.trim();
  if (!COUNT_RE.test(normalized)) return null;
  const count = Number(normalized);
  const value = count * 1000;
  return Number.isSafeInteger(value) && value <= 999_999_999_000
    ? value
    : null;
}

export function quantityText(value: number): string {
  if (!Number.isSafeInteger(value) || value < 0) {
    throw new RangeError('Invalid quantity');
  }
  const fraction = String(value % 1000)
    .padStart(3, '0')
    .replace(/0+$/, '');
  return `${Math.floor(value / 1000)}${fraction ? `.${fraction}` : ''}`;
}

export function countText(value: number): string {
  if (!Number.isSafeInteger(value) || value < 0 || value % 1000 !== 0) {
    throw new RangeError('Invalid count');
  }
  return String(value / 1000);
}

/** Validates the target for a habit kind; returns null when invalid. */
export function parseTarget(
  kind: 'check' | 'quantity' | 'count',
  input: string,
): number | null {
  if (kind === 'check') return input.trim() === '' ? 1000 : null;
  return kind === 'quantity' ? parseQuantity(input) : parseCount(input);
}

export function isValidRecordValue(
  kind: 'check' | 'quantity' | 'count',
  value: number,
): boolean {
  if (!Number.isSafeInteger(value) || value < 0) return false;
  if (kind === 'check') return value === 1000;
  if (kind === 'count') return value % 1000 === 0;
  return true;
}