Task: Fully Install, Configure, Integrate, and Verify Taste Skills v2 and Context7 in OpenCode

You are operating directly inside the current OpenCode environment. Your task is to actually perform the installation, configuration, integration, verification, and troubleshooting described below.

Do not merely provide instructions or explain how to do it. Execute the required changes directly in the current environment.

1. Install and Integrate Taste Skills v2

Install Taste Skills v2 from the official source:

https://www.tasteskill.dev/

Requirements:

- Determine the correct and current installation method for Taste Skills v2.
- Install it into the current OpenCode environment using the officially recommended mechanism whenever possible.
- Ensure that all required files, directories, configuration entries, dependencies, and integrations are created correctly.
- Integrate Taste Skills v2 with OpenCode so that the AI can actually discover and use the skills.
- Inspect the existing OpenCode configuration before making changes.
- Preserve existing functionality and avoid overwriting unrelated configuration.
- If an existing Taste Skills installation or older version is present, determine whether it should be upgraded, migrated, or preserved before making changes.
- Use the latest compatible version available from the official source unless the environment explicitly requires another version.

2. Install and Configure Context7

Integrate Context7 into the current OpenCode environment.

Use the following API key:

"ctx7sk-12004253-ce0f-4f10-aece-4c73303586c9"

Requirements:

- Determine the correct and current Context7 integration method for OpenCode.
- Configure Context7 using the appropriate OpenCode MCP/tool configuration mechanism.
- Store the configuration in the correct location used by the current OpenCode installation.
- Ensure the API key is supplied through the appropriate configuration mechanism and is actually usable by Context7.
- Prefer secure handling of the API key and avoid unnecessarily exposing it in logs, generated documentation, or command output.
- Do not create duplicate or conflicting Context7 configurations.
- Inspect existing MCP/tool configuration before modifying it.
- Preserve all unrelated existing MCP servers, tools, permissions, and configuration.

3. Automatic Availability and Usage

This is a critical requirement.

After installation, configure the environment so that Taste Skills v2 and Context7 are available to the AI automatically whenever appropriate, without requiring the user to explicitly tell the AI to activate them every time.

Specifically:

- Skills should be automatically discoverable by the AI according to the supported OpenCode/Taste Skills mechanism.
- Context7 should be automatically available as an MCP/tool integration when relevant.
- Do not implement this by blindly forcing every skill or MCP tool to run on every request.
- Instead, configure the environment according to the supported mechanisms for automatic discovery, availability, and intelligent tool/skill selection.
- Ensure the AI can independently determine when a Taste Skill or Context7 should be used.
- Verify that automatic discovery/availability actually works rather than assuming it works because configuration files exist.

4. Inspect the Existing Environment First

Before modifying anything:

1. Inspect the current OpenCode version and environment.
2. Locate the active OpenCode configuration files/directories.
3. Inspect existing MCP/server/tool configurations.
4. Inspect existing skills and skill-loading mechanisms.
5. Check whether Taste Skills, Context7, or related integrations are already installed.
6. Identify potential version conflicts, duplicate configurations, invalid configuration syntax, or incompatible mechanisms.
7. Determine the safest integration strategy based on the actual environment.

Do not assume paths, configuration formats, command names, or installation procedures without checking the current environment and official documentation.

5. Execute the Installation and Configuration

Perform all required changes directly.

You are authorized to:

- Create required directories and files.
- Modify OpenCode configuration files.
- Install required packages/dependencies.
- Update existing configuration where necessary.
- Add or update MCP server definitions.
- Install or update skills.
- Restart/reload/reinitialize relevant OpenCode components when required.
- Run diagnostic commands.
- Test the resulting integrations.

However:

- Do not delete unrelated configuration.
- Do not replace an existing configuration wholesale when a targeted modification is sufficient.
- Do not remove existing MCP servers, tools, or skills unless they are demonstrably obsolete or conflicting and there is no safer solution.
- Before destructive changes, create an appropriate backup or preserve the previous configuration.
- Keep changes minimal, compatible, and reversible where practical.

6. Actual Verification — Do Not Trust Configuration Files Alone

After completing the installation, perform real functional verification.

Do NOT consider the task successful merely because configuration files were created or because commands exited without obvious errors.

Verify all of the following:

Taste Skills v2

- Confirm the expected Taste Skills v2 files/components are installed.
- Confirm OpenCode can discover the installed skills.
- Confirm the skill-loading mechanism works.
- Confirm at least one Taste Skill can actually be discovered/read/loaded by the AI environment.
- Check for errors related to skill discovery, permissions, paths, dependencies, or version compatibility.

Context7

- Confirm the Context7 MCP configuration is syntactically valid.
- Confirm OpenCode recognizes the Context7 MCP server/tool.
- Confirm the MCP server can initialize successfully.
- Confirm authentication/API-key configuration is accepted.
- Confirm the Context7 tools are actually accessible to the AI.
- Where technically possible, perform a real Context7 tool operation to prove that the integration works.
- Distinguish between "configuration exists" and "MCP server is actually operational."

Integration

Verify that:

- Taste Skills v2 is available to OpenCode.
- Context7 is available to OpenCode.
- Both can be used by the AI.
- Automatic discovery/availability works as intended.
- Existing OpenCode functionality remains intact.
- Existing MCP servers/tools/skills continue to work.
- There are no configuration conflicts, duplicate entries, invalid paths, or startup errors caused by these changes.

7. Troubleshooting and Self-Repair

If anything fails:

1. Diagnose the actual error.
2. Determine the root cause.
3. Consult the relevant official documentation/source when necessary.
4. Fix the configuration or installation directly.
5. Re-run the failed verification.
6. Continue troubleshooting until the integration works or until a genuine external limitation prevents completion.

Do not stop at "this may be the problem." Investigate and verify the cause.

Do not declare success based on assumptions.

If the first installation/integration method is incompatible with the current OpenCode version, determine the correct compatible method and use it instead.

8. Security and Configuration Hygiene

Handle the Context7 API key carefully.

- Do not unnecessarily print the full API key in the final report.
- Do not place the API key into unrelated files.
- Do not expose the API key in logs, README files, comments, or diagnostic output unless absolutely required.
- If the supported configuration mechanism allows environment variables or another safer secret-management method, prefer it where appropriate.
- Verify that the final configuration actually resolves the credential correctly.

9. Final Verification Checklist

Before reporting completion, verify every item below:

- [ ] Taste Skills v2 is installed.
- [ ] Taste Skills v2 is discoverable by OpenCode.
- [ ] Taste Skills v2 can actually be loaded/used.
- [ ] Context7 is configured.
- [ ] Context7 MCP is recognized by OpenCode.
- [ ] Context7 MCP can initialize successfully.
- [ ] Context7 authentication works.
- [ ] Context7 tools are accessible to the AI.
- [ ] Taste Skills and Context7 can be used automatically when relevant.
- [ ] Existing OpenCode configuration remains functional.
- [ ] No unnecessary duplicate or conflicting configuration exists.
- [ ] Actual functional verification has been performed.
- [ ] Any detected problems have been fixed and re-tested.

10. Final Report

Once the work is complete, provide a short, factual completion report containing:

1. Taste Skills v2: installation status and verification result.
2. Context7: configuration status and verification result.
3. Integration: how each component is integrated into OpenCode.
4. Automatic usage: whether the AI can automatically discover/use them when relevant.
5. Verification: summarize the actual tests performed and their results.
6. Changes made: briefly identify the important configuration/files/components modified.
7. Problems: list any unresolved issues or limitations.
8. Required user action: only if something genuinely requires manual intervention.

Use clear statuses such as:

- "PASS" — installed/configured and functionally verified.
- "PARTIAL" — partially working, with a specific limitation.
- "FAIL" — not working, with the diagnosed reason.

Important Execution Rules

DO NOT:

- Only provide a tutorial.
- Merely describe commands the user should run.
- Claim success because a configuration file exists.
- Assume an MCP server works without testing it.
- Assume skills are available without verifying discovery/loading.
- Invent configuration paths or commands without checking the actual environment.
- Ignore existing OpenCode configuration.
- Replace unrelated configuration unnecessarily.
- Stop troubleshooting at the first error.

DO:

- Inspect the actual environment first.
- Use the current/official installation and integration mechanisms.
- Make the changes directly.
- Verify the result functionally.
- Diagnose and fix problems.
- Re-test after fixes.
- Preserve existing configuration and functionality.
- Ensure the integrations are automatically available to the AI when relevant.
- Report only what has actually been verified.

Primary objective:

«Leave the current OpenCode environment in a state where Taste Skills v2 and Context7 are genuinely installed, correctly integrated, automatically discoverable/available to the AI when relevant, and functionally verified, while preserving the existing OpenCode setup.»
