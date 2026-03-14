# Manual run (no real PR)

To run the workflow without a GitHub webhook (e.g. from n8n “Execute workflow”):

1. Use a **Manual trigger** or **Webhook** with a test payload that includes `pull_request` and `repository`.
2. Add a node that provides the PR files array (e.g. HTTP Request to `GET /repos/:owner/:repo/pulls/:number/files` with a fixed PR number, or a Code node that returns a mock array of `{ filename, status, patch }`).
3. Connect that output to Filter files, then run Build prompt → AI → Format comment. Post comment step will need a real repo/PR if you want the comment to appear on GitHub.
