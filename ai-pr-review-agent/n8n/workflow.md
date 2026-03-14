# n8n Workflow: GitHub PR AI Review

## Recommended node order

1. **Webhook** – Trigger on GitHub `pull_request`. Output: event payload (root or in `body`).

2. **Get PR files** (required) – GitHub does not send file list in the webhook. Add an HTTP Request node:
   - Method: GET
   - URL: `https://api.github.com/repos/{{ $json.repository.full_name }}/pulls/{{ $json.pull_request.number }}/files`
   - Headers: `Authorization: Bearer {{ $env.GITHUB_TOKEN }}`, `Accept: application/vnd.github.v3+json`
   - Connect input from Webhook (one item). Output is the array of `{ filename, status, patch }`; pass this single item to Filter files.

3. **Filter files** – Code node with `filter-files.js`.
   - Input: one item whose `json` is the array of PR files (or `json.body` / `json.data`).
   - Output: `{ relevant_files: [...] }`.

4. **Build prompt** – Code node with `build-prompt.js`.
   - Must have access to **Webhook** node (same workflow). Uses `$('Webhook').first().json` (payload at root or in `.body`).
   - Input: output of Filter files (`relevant_files`).
   - Output: `{ pr_title, prompt, relevant_files }`. Pass `prompt` to the AI node.

5. **AI** – OpenAI / Anthropic / etc. node.
   - Input: `prompt` from previous node.
   - Output: raw text (e.g. `text`, `output`, `response`, or `content`).

6. **Format comment** – Code node with `format-comment.js`.
   - Input: AI node output.
   - Output: `{ comment_body }` for the next step.

7. **Post comment to GitHub** – HTTP Request:
   - URL: `https://api.github.com/repos/{{ $('Webhook').first().json.repository.full_name }}/issues/{{ $('Webhook').first().json.pull_request.number }}/comments`
   - Body: use Expression `{{ { body: $json.comment_body } }}`
   - Headers: `Authorization: Bearer {{ $env.GITHUB_TOKEN }}`, `Content-Type: application/json`

## Notes

- Webhook and Get PR files must run in the same workflow so Build prompt and Post comment can use `$('Webhook').first().json`.
- If you use “Get PR files”, connect it so that its output is the only input to Filter files (one item with the files array in `json` or `json.body`).
