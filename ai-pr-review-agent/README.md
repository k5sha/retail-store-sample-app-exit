# AI PR Review Agent

n8n-based workflow that runs an AI review on Pull Requests (Kubernetes, Helm, Dockerfile, CI/CD).

## For contributors

When you open a **Pull Request** (from your fork or from a branch), the repo’s webhook triggers an automatic AI review. You don’t need to do anything extra: just push your branch and create the PR. The bot will post a comment with findings (image tags, probes, resources, security, etc.) and a recommendation. All contributors get the same review flow.

## What it does

- Receives GitHub PR webhook (any contributor’s PR).
- Filters changed files to DevOps-relevant ones (YAML, Dockerfile, values, deployments, `.github/workflows`).
- Builds a prompt and calls an AI model to produce a structured review (findings, severity, recommendations).
- Posts a GitHub comment with the review.

## Requirements

- [n8n](https://n8n.io) (self-hosted or cloud).
- GitHub token with `repo` scope (or GitHub App) that can **post comments on this repo** — so it works for **all contributors’ PRs**, not only the token owner’s.
- AI node in n8n (OpenAI, Anthropic, or similar) for the review step.

## Setup (repo maintainers)

So that **any contributor’s PR** triggers the review:

1. Copy env example and set secrets:
   ```bash
   cp n8n/env.example .env
   # Edit .env: GITHUB_TOKEN (must have repo access to this repository), WEBHOOK_URL
   ```
2. Use a **repository-level** token (PAT with `repo` or a **GitHub App** installed on the repo). That way the bot can read and comment on PRs from any user.
3. Import or create the workflow in n8n (see `n8n/workflow.md`).
4. Add a **repository webhook** (Settings → Webhooks → Add webhook):
   - **Payload URL:** your `WEBHOOK_URL` (must be reachable from the internet for GitHub).
   - **Content type:** `application/json`.
   - **Events:** choose **Pull requests** (triggers on opened, synchronize, reopened, etc.).
   - Save; GitHub will send a request for every PR event from any contributor.
5. Add an n8n “Get PR files” HTTP Request node (GitHub does not send file list in the webhook): `GET /repos/{owner}/{repo}/pulls/{pull_number}/files` with `GITHUB_TOKEN`, then pass the response into the filter-files code node. See `n8n/workflow.md`.

## Structure

- **n8n/code/** – Code nodes: `filter-files.js`, `build-prompt.js`, `format-comment.js`.
- **n8n/prompts/** – Prompt reference (`pr-review-prompt.md`).
- **docs/** – Architecture, for-contributors, demo-scenario (manual run).

## Usage

Open a PR (as any contributor); the webhook runs the workflow and the AI review is posted as a comment (if the workflow includes the “Post comment” step).
