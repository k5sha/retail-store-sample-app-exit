const raw =
  $json.text ||
  $json.output ||
  $json.response ||
  $json.content ||
  $json.message?.content ||
  ($json.choices && $json.choices[0]?.message?.content) ||
  '## AI PR Review Summary\nNo review generated.';

return [{
  json: {
    comment_body: raw
  }
}];