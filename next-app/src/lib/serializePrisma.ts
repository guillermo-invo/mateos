import { Prisma } from '@prisma/client';

function convertPrismaValue(value: unknown): unknown {
  if (value === null || value === undefined) {
    return value;
  }

  if (typeof value === 'bigint') {
    return Number(value);
  }

  if (value instanceof Prisma.Decimal) {
    return value.toNumber();
  }

  if (value instanceof Date) {
    return value;
  }

  if (value instanceof Buffer) {
    return value;
  }

  if (Array.isArray(value)) {
    return value.map((item) => convertPrismaValue(item));
  }

  if (typeof value === 'object') {
    const converted: Record<string, unknown> = {};
    for (const [key, val] of Object.entries(value as Record<string, unknown>)) {
      converted[key] = convertPrismaValue(val);
    }
    return converted;
  }

  return value;
}

export function serializePrismaData<T>(data: T): T {
  return convertPrismaValue(data) as T;
}
