// Spectral custom function for the fb-*-format rules (04 §4.2 Formats).
//
// Input: a (resolved) property schema. Options: { format: 'uuid' | 'date-time' | 'date' }.
// Passes when the schema has that `format` itself (a type-array nullable such
// as `type: [string, 'null']` keeps it there) or in one branch of a
// oneOf/anyOf null-wrap. Reports one result per property.
//
// No imports on purpose: the container runs offline.

function hasFormat(schema, format) {
  if (schema === null || typeof schema !== 'object') return false;
  if (schema.format === format) return true;
  return ['oneOf', 'anyOf', 'allOf'].some(
    (k) => Array.isArray(schema[k]) && schema[k].some((branch) => branch && branch.format === format),
  );
}

export default function fbHasFormat(input, options, context) {
  if (hasFormat(input, options.format)) return [];
  const name = context.path[context.path.length - 1];
  return [{ message: `Property '${name}' must have format: ${options.format}.`, path: [...context.path] }];
}
