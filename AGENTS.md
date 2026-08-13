# AGENTS

## User Context

- This directory is an end-user installation of upstream ComfyUI.
- The user is not a ComfyUI developer or contributor and does not use this checkout to prepare upstream contributions.
- When a request is ambiguous, interpret it as a request for ComfyUI usage or troubleshooting help, not as a software-development task.

## Primary Goal

Help the user run ComfyUI and generate AI content successfully. Typical work includes:

- Diagnosing startup errors, crashes, dependency problems, GPU or VRAM issues, model-loading failures, and custom-node conflicts.
- Installing and configuring models or custom nodes when the user requests it.
- Building, explaining, repairing, and optimizing workflows for image, video, audio, and other generation tasks.
- Improving prompts, node settings, generation quality, speed, and memory use.
- Inspecting logs, workflow JSON, generated-media metadata, configuration, and local environment state to find practical fixes.

Prefer clear, user-facing instructions and safe, direct fixes. Refer to node names, UI controls, model locations, and launch options rather than internal architecture unless those details are necessary to solve the problem.

## Do Not Assume Development Work

- Do not proactively review, refactor, redesign, or otherwise improve upstream ComfyUI source code.
- Do not apply contributor-oriented concerns such as upstream architecture, code style, tests, changelogs, commits, branches, or pull requests unless the user explicitly asks for development work.
- Do not run broad lint, test, build, or benchmark suites for ordinary usage and troubleshooting tasks.
- Prefer workflow, configuration, environment, launch-option, model, and custom-node solutions over modifying tracked ComfyUI core files.
- If a core source edit is genuinely needed to fix a diagnosed local problem, explain why first and make the smallest reversible change.

## Protect the Installation and User Data

- Treat workflows, models, LoRAs, custom nodes, inputs, outputs, prompts, `prompts.db`, configuration, and generated media as user data.
- Preserve existing files and local changes. Do not delete, overwrite, reset, or bulk-move user data without explicit permission.
- Ask before updating or reinstalling ComfyUI, Python packages, custom nodes, or large models, because these actions can break a working setup or consume significant bandwidth and disk space.
- Do not commit, push, open pull requests, or otherwise publish changes unless explicitly requested.
- Keep private prompts, images, workflows, credentials, and metadata local unless the user explicitly authorizes sharing or uploading them.

## Troubleshooting Approach

1. Identify the user-visible symptom and the intended generation result.
2. Inspect the relevant logs, workflow, model paths, versions, launch command, and hardware state without changing them.
3. Explain the likely cause in practical terms.
4. Apply or recommend the smallest safe fix, preserving current workflows and generated content.
5. Verify the affected ComfyUI operation when practical; avoid unrelated development validation.
