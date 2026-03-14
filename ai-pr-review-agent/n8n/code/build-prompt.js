// GitHub webhook: payload can be in .body or at root
const wh = $('Webhook').first().json;
const payload = wh && wh.body && typeof wh.body === 'object' ? wh.body : wh || {};
const relevantFiles = $json.relevant_files || [];

const pullRequest = payload.pull_request || payload;
const prTitle = pullRequest.title || 'Untitled PR';
const prBody = pullRequest.body || '[empty]';

const filesText = relevantFiles.map(file => {
  return [
    `FILE: ${file.filename}`,
    `STATUS: ${file.status}`,
    `PATCH:`,
    file.patch
  ].join('\n');
}).join('\n\n---\n\n');

const prompt = `
You are a senior DevOps reviewer for a retail-store app repo: Helm charts (orders, catalog, checkout, cart, ui), Argo CD in deploy/gitops, ECR images, Terraform EKS, stateful (PostgreSQL, MySQL, Redis). Focus on changes that affect deploy, charts, and CI/CD.

Analyze this Pull Request for Kubernetes, Helm, Dockerfile, Argo CD/Application manifests, and CI/CD risks.

Return a concise GitHub-ready markdown review in this exact structure:

## AI PR Review Summary
**PR:** <title>
**Files analyzed:** <count>
**Overall risk:** Low | Medium | High

### Findings
For each finding use:
- Severity: HIGH | MEDIUM | LOW
- File
- Issue
- Why it matters
- Recommendation

### Final recommendation
Choose one:
- Approve with minor fixes
- Request changes
- Needs manual review

Focus on:
- image tags like latest
- missing readiness/liveness probes
- missing resources requests/limits
- missing securityContext
- runAsNonRoot/readOnlyRootFilesystem
- privileged or root execution
- hardcoded secrets
- dangerous CI/CD permissions
- configuration anti-patterns

PR TITLE:
${prTitle}

PR BODY:
${prBody}

FILES:
${filesText}
`.trim();

return [{
  json: {
    pr_title: prTitle,
    prompt,
    relevant_files: relevantFiles
  }
}];