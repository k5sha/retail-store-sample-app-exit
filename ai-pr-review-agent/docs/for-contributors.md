# For contributors: automatic PR review

When you open a **Pull Request** to this repository (from a fork or from a branch), an AI review runs automatically.

## What you need to do

1. Push your branch and create a PR as usual (no extra steps).
2. Wait a short time; a bot will post a comment on your PR with:
   - A short summary and risk level
   - Findings (e.g. image tags, probes, resources, security)
   - A final recommendation (approve with fixes / request changes / manual review)

## Who gets the review

**Every** PR that targets the configured branch(es) and is sent to this repo will trigger the review — whether you are a first-time contributor or a maintainer. The same webhook and n8n workflow handle all contributors.

## If no comment appears

- The webhook might be disabled or the n8n workflow might be down; ask the repo maintainers.
- Check that the webhook is set for **Pull requests** and that the n8n URL is reachable from the internet.
