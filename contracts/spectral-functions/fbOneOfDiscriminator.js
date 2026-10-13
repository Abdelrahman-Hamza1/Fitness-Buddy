// Spectral custom function for rule fb-oneof-discriminator (S02 A4).
//
// Input: a (resolved) schema object that has a `oneOf` and/or an `anyOf`. Each
// of the two is checked on its own, the same way:
// - A null-wrap passes: exactly two branches, one of them `{type: 'null'}` (how
//   a nullable reference is written in OpenAPI 3.1).
// - Any other union needs `discriminator.propertyName` and a
//   `discriminator.mapping` with one entry per branch, and every branch must
//   list that property in `required` (directly or in one of its `allOf` parts).
// - A `{type: 'null'}` branch is only allowed in a null-wrap: a nullable union is
//   written as a null-wrap around a $ref to the discriminated union.
// The Dart generator turns a discriminated union into a sealed class with a
// fallback variant; without a discriminator it can only guess, and a branch
// missing from the mapping can't be decoded.
//
// No imports on purpose: the container runs offline, and Spectral would try to
// fetch anything it can't resolve locally.

function isNullBranch(branch) {
  return (
    branch !== null &&
    typeof branch === 'object' &&
    (branch.type === 'null' || (Array.isArray(branch.type) && branch.type.length === 1 && branch.type[0] === 'null'))
  );
}

function requiredOf(schema, seen) {
  const names = new Set();
  if (schema === null || typeof schema !== 'object' || seen.has(schema)) return names;
  seen.add(schema);
  if (Array.isArray(schema.required)) schema.required.forEach((n) => names.add(n));
  if (Array.isArray(schema.allOf)) {
    schema.allOf.forEach((part) => requiredOf(part, seen).forEach((n) => names.add(n)));
  }
  return names;
}

function checkUnion(input, keyword, path) {
  const branches = input[keyword];
  const nullCount = branches.filter(isNullBranch).length;
  if (branches.length === 2 && nullCount === 1) return [];

  const d = input.discriminator;
  if (d === null || typeof d !== 'object' || typeof d.propertyName !== 'string' || d.propertyName === '') {
    return [{ message: `${keyword} needs discriminator.propertyName (only a two-branch null-wrap may omit it).`, path: [...path, keyword] }];
  }

  const results = [];
  const nonNull = branches.length - nullCount;
  const mapped = d.mapping !== null && typeof d.mapping === 'object' ? Object.keys(d.mapping).length : 0;
  if (mapped !== nonNull) {
    results.push({
      message: `${keyword} discriminator "${d.propertyName}" needs a mapping with one entry per branch (${nonNull}), has ${mapped}.`,
      path: [...path, 'discriminator'],
    });
  }
  branches.forEach((branch, i) => {
    if (isNullBranch(branch)) {
      results.push({
        message: `${keyword} branch ${i} is {type: 'null'}: only a two-branch null-wrap may have one (wrap a $ref to the union instead).`,
        path: [...path, keyword, i],
      });
    } else if (!requiredOf(branch, new Set()).has(d.propertyName)) {
      results.push({
        message: `${keyword} branch ${i} must list the discriminator property "${d.propertyName}" in required.`,
        path: [...path, keyword, i],
      });
    }
  });
  return results;
}

export default function fbOneOfDiscriminator(input, _options, context) {
  if (input === null || typeof input !== 'object') return [];
  const results = [];
  for (const keyword of ['oneOf', 'anyOf']) {
    if (Array.isArray(input[keyword])) results.push(...checkUnion(input, keyword, context.path));
  }
  return results;
}
