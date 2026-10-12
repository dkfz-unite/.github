# Connecting a workspace to shared documentation

Last updated: 2026-10-07.

## One shared source, workspace and component entry points

The organization's `.github` repository stores common instructions in
[AGENTS.md](../AGENTS.md), a task index in [README.md](../README.md), and
architecture/workflows in `docs/`. The usual agent project (Codex or Claude
Code) is the parent source workspace, containing multiple independent Git
repositories.

The workspace root `AGENTS.md` explicitly directs the agent to the shared
checkout. Before editing a component, it also directs the agent to that
component's instructions and README. Component repositories keep API/format
and setup documentation plus any local agent clarifications. Their own short
entry points also support tasks opened directly in an individual repository.

These entry points do not copy the common working rules. Changing architecture
or a shared rule normally requires a change only here. A workspace-entry-point
template is versioned here so team members use the same loading convention,
even though their parent source folders are local directories rather than a
shared Git repository.

Codex discovers instructions from its global configuration and the current
project's root-to-working-directory chain. It does not automatically discover
an unrelated sibling checkout or inherit organization `.github` instructions.
A Markdown link is not an automatic import: our entry points explicitly ask the
agent to read the target files. When working from the parent workspace, the
workspace instruction explicitly requires reading component instructions before
editing; do not depend on a descendant file being included at chat startup.
See the [official OpenAI documentation](https://learn.chatgpt.com/docs/agent-configuration/agents-md).

## Claude Code

Claude Code reads `CLAUDE.md` rather than `AGENTS.md`. Each location that has
an `AGENTS.md` also has a `CLAUDE.md` containing only `@AGENTS.md`, which
imports the neighbouring file. `AGENTS.md` remains the single source; never add
instructions to `CLAUDE.md` itself, or the two agents will diverge.

Claude Code loads the `CLAUDE.md` files from the working directory upward at
session start, and loads a subdirectory's `CLAUDE.md` when it reads files in
that directory. The explicit reading steps in the entry points still apply; as
with Codex, an `@` import or Markdown link elsewhere in the shared documents is
not a substitute for reading the relevant topic documents. See the
[Claude Code memory documentation](https://docs.claude.com/en/docs/claude-code/memory).

## Skills

Skills are step-by-step procedures for repeated tasks (for example logging a
defect or running a service locally). Each is a folder with a `SKILL.md` file
whose frontmatter has a `name` and a `description`; the agent sees only these
until a task matches the description or the user invokes the skill by name
(`/name` in Claude Code, `$name` in Codex). Use `AGENTS.md` for what the project
is and its rules, and skills for procedures.

Shared UNITE skills live in [`skills/`](../skills) in this repository, in the
format both tools read. Claude Code discovers skills in `.claude/skills/`,
Codex in `.agents/skills/`; both scan the start folder and its parents up to
the Git repository root, plus a user folder (`~/.claude/skills`,
`~/.agents/skills`), and both follow symlinks. The source workspace is not a
Git repository, so link the skills there:

```sh
sh unite-meta/scripts/link-skills.sh          # <workspace>/.claude/skills and .agents/skills
sh unite-meta/scripts/link-skills.sh --user   # also when starting inside a single repository
```

Keep skills tool-neutral: only `name` and `description` in the frontmatter, no
tool-specific fields, and no security findings (this repository is public).
After adding a skill, run the script again to link it. References:
[Claude Code skills](https://code.claude.com/docs/en/skills),
[Codex skills](https://developers.openai.com/codex/skills).

## Team setup: work from the parent workspace

From the directory containing source repositories, clone this repository once:

```sh
git clone https://github.com/dkfz-unite/.github.git unite-meta
```

Use an existing checkout if already cloned. A sibling checkout named `.github`
is also supported. Keep it updated through the team's normal Git workflow;
instructions do not automatically pull or switch branches.

If the workspace has no root `AGENTS.md`, install the small entry-point template:

```sh
cp unite-meta/templates/workspace-AGENTS.md AGENTS.md
cp unite-meta/templates/CLAUDE.md CLAUDE.md
```

If a workspace `AGENTS.md` already exists, merge the template's loading guidance
into it instead of overwriting local instructions. The project owner's current
`projects/AGENTS.md` has already been created from this template. Future template
changes should be merged into installed entry points; changing shared rules or
topic documents does not require refreshing this small file.

Keep the parent workspace as the agent project and start chats there. Its
`AGENTS.md` loads the shared context and tells the agent to read component
instructions as needed. There is no need to create a separate project for
every repository or change personal `~/.codex` or `~/.claude` configuration. Each affected
repository has its own Git status, branch, and build directory.

For a different folder layout, provide the shared checkout path in the task or
adapt the small workspace entry point. Installation plugins may be nested below
`unite-env` and cannot use the usual sibling path. If a local checkout is
unavailable, the entry points direct the agent to GitHub. Remote fallback needs
network access and repository permission; isolated/cloud environments may need
the shared checkout provisioned alongside the source. Missing context must be
reported explicitly.

## Component instructions and new repositories

Use component `AGENTS.md` files for developer- and agent-specific details such
as code layout, where to change things, pitfalls and verification steps. API
endpoints, data models, formats, configuration and installation belong in the
repository's human-readable `README.md` and `Docs/`, which `AGENTS.md` links to
instead of repeating. Keep common rules in this shared repository. The workspace loader reads component guidance before editing, and
existing component entry points also support a chat opened directly there.

For a new repository, copy [the component template](../templates/repository-AGENTS.md)
to its root `AGENTS.md` and fill in its component section, following the
completed examples in `unite-composer` and `unite-feed-omics`. Copy
[the Claude template](../templates/CLAUDE.md) next to it as `CLAUDE.md`. If a
file already exists, merge the shared loading instruction instead of replacing
its rules.
Add this near the beginning of its README:

```markdown
Shared architecture, development workflows, and agent instructions:
[UNITE project documentation](https://github.com/dkfz-unite/.github/blob/main/README.md).
```

Publish `.github` and component changes through the team's usual Git workflow.
Teammates receive versioned templates and documentation after publication and
pulling, then install the workspace entry point once. New shared links become
usable on GitHub after the documents are published. Repositories not currently
cloned have not been modified.

## Check the setup from the parent workspace

Start a new chat in the existing parent-workspace project and send:

> Do not change anything. Read the workspace instructions and shared UNITE
> documentation. List the AGENTS.md files you actually read and their paths.
> Explain what unite-composer does and which documentation and repositories
> are relevant to changing search and private-project visibility. Read the
> component instructions for those repositories too.

The agent should identify the workspace `AGENTS.md`, the shared
`unite-meta/AGENTS.md` (or an explicitly identified fallback), relevant component
instructions, and the topic documents it read. This checks actual agent loading
behavior; Markdown link checks alone verify navigation, not a fresh chat.

## Maintain the structure

Use the shared README as the single topic index. Keep working rules in the shared
`AGENTS.md`, domain/architecture/workflows in topic documents, and component
setup/API/file contracts with the source repository. Add new topic documents when
a subject warrants its own page; update the index and avoid duplicating contents
across repositories. Profile material remains a public introduction and
supporting diagrams, with its verification scope recorded.
