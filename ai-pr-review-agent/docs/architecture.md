# Architecture

## Flow

```
GitHub (PR event) → Webhook → [Get PR files] → Filter files (Code) → Build prompt (Code) → AI → Format comment (Code) → Post comment (HTTP)
```

- **Webhook**: receives GitHub `pull_request` payload (or manual trigger).
- **Get PR files**: optional; fetches `/repos/:owner/:repo/pulls/:number/files` when the webhook does not include file diffs.
- **Filter files**: keeps only DevOps-relevant paths (YAML, Dockerfile, values, deployment, service, ingress, `.github/workflows`).
- **Build prompt**: builds a single prompt from PR title, body, and filtered file patches; references Webhook node for payload.
- **AI**: returns a markdown review (findings, severity, recommendation).
- **Format comment**: normalizes AI output into `comment_body`.
- **Post comment**: posts `comment_body` to the PR via GitHub API.

## Dependencies

- n8n (with Code and HTTP Request nodes).
- AI credentials (OpenAI, Anthropic, or compatible).
- GitHub token with `repo` (and `write:discussion` if posting comments).

## Configuration

- `GITHUB_TOKEN`: used to fetch PR files and/or post the review comment.
- `WEBHOOK_URL`: URL of the n8n webhook (for GitHub webhook configuration).
- `N8N_HOST`: base URL of n8n (optional, for links in docs).
