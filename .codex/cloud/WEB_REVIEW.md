# External GPT planning and review

Preserve the existing Ambush Loop reviewer Project:
https://chatgpt.com/g/g-p-6ab943ae67ac81919bcbe3cd35ebe3b7/project

Existing conversation:
https://chatgpt.com/g/g-p-6ab943ae67ac81919bcbe3cd35ebe3b7-ambush-loop-collab/c/6aba7f25-906c-83ec-8054-159a82a62b20

## Revision identity is mandatory

The established `Codex with ChatGPT · ambush-loop-collab` connection serves a LOCAL checkout, not this cloud branch. Its previous session concerns Android/audio diagnostics: do not overwrite that session or reset its dirty checkout. A successful local doctor does not establish cloud review access.

Use either an authorized GitHub source that can read the exact `hailinsu-create/ambush-loop` commit, or a separately verified clean review checkout at that commit. With Codex with ChatGPT, follow its installed skill, verify `workspace_info` and an actual `read_file` against a file changed in the target revision. For a new checkout/connector, request only the necessary authorization. Never silently change the existing connector workspace.

Send a short control message naming PLAN or REVIEW, exact branch/SHA, scope and evidence paths. The reviewer reads repository content through its connection; do not paste repository files, diffs, phone logs, or screenshots into the chat as a substitute for source access. Existing permission to share phone evidence is not a mandate to publish personal data in GitHub.

## PLAN

Ask for the next single playable or visual slice, dependencies, non-goals, focused gates, and rollback/stop conditions. Preserve SCOUT → ALERT → SWEEP, the design-v2 baseline and separate Engine/Look workstreams. Store actual feedback and the adopted plan separately.

## REVIEW

Provide exact implementation SHA and test evidence paths. Ask for blocking defects and explicitly distinguish code review, desktop/headless validation, in-engine visuals, and Android/device acceptance. Record the review's source identity, actual response, approval status and unresolved issues in a dated document. If access fails or the reviewer reads an old SHA, status is `unavailable`, not approve.

Cloud environment publication and the first exact-cloud-revision web review remain pending until proven live. Historical GPT reviews remain historical evidence, not approval of this migration.
