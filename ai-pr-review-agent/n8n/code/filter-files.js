// Support different input shapes: array of files, or { body/data: array }
const raw = items[0]?.json;
const files = Array.isArray(raw) ? raw : (raw?.body ?? raw?.data ?? []);
const relevant = [];

for (const file of files) {
  const name = (file.filename || '').toLowerCase();

  const isRelevant =
    name.endsWith('.yaml') ||
    name.endsWith('.yml') ||
    name === 'dockerfile' ||
    name.endsWith('/dockerfile') ||
    name.includes('values') ||
    name.includes('deployment') ||
    name.includes('service') ||
    name.includes('ingress') ||
    name.includes('statefulset') ||
    name.includes('.github/workflows') ||
    name.includes('helmfile') ||
    name.includes('chart/') ||
    (name.includes('deploy/') && (name.includes('gitops') || name.includes('application'))) ||
    (name.includes('terraform/') && name.endsWith('.yaml'));

  if (!isRelevant) continue;

  relevant.push({
    filename: file.filename,
    status: file.status || 'modified',
    patch: file.patch || '[no patch available]'
  });
}

return [{ json: { relevant_files: relevant } }];