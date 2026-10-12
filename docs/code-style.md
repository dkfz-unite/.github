# Code style and principles

Last updated: 2026-10-12.

How the UNITE team writes code. The rules come from the owner and are updated
regularly; when existing code differs, follow these rules in new and changed
code, without rewriting unrelated code.

Code is a book: it should be easy and pleasant to read. Choose the simplest
code that does the job well.

## Editor settings

Every repository has the same `.editorconfig` and `.gitattributes`, copied from
[`templates/editorconfig`](../templates/editorconfig) and
[`templates/gitattributes`](../templates/gitattributes) (2026-10-12): UTF-8
without BOM, LF line endings (also enforced by Git), a final newline, trimmed
trailing whitespace, 4 spaces in C# and 2 elsewhere, file-scoped namespaces,
`var`, no primary constructors. All team IDEs read `.editorconfig`; VS Code
needs the EditorConfig extension. Change the templates first, then copy them to
the repositories. Existing files are not reformatted in bulk; editors apply the
settings to what you change. Two blank lines between groups cannot be expressed
in `.editorconfig`; follow it by hand.

## Principles

- **Common sense first.** Follow SOLID and KISS, but UNITE is a relatively small
  project with a small team, not an enterprise system. Write what makes sense;
  leave out patterns, layers and abstractions that only add ceremony.
- **Abstractions where they pay off**, and not deep. Prefer one clear level of
  abstraction over chains of interfaces and base classes.
- **Look for global patterns.** When the same logic is used, or is going to be
  used, in many places, make it shared code. Prefer declarative use (configure
  what should happen) over repeated imperative code.
- **Performance and resources matter where they really matter.** UNITE runs
  within fairly tight resource limits: think about memory and queries on large
  data (variants, expressions, analyses), and do not optimize code that does
  not need it.
- **Review priority**: correct functionality first; style and conventions are
  important but secondary, especially where code differs from the settled
  standards.

## C#

### Files and structure

- File-scoped namespaces.
- One class per file. Exception: a file may keep very similar things together,
  such as closely related data models, or validators for a single entry and
  for a collection of entries.
- Order inside a class:
  1. constants
  2. private readonly fields
  3. private fields
  4. public fields and properties
  5. constructor
  6. public methods
  7. private methods
- **Two blank lines between groups** (constants, fields, properties,
  constructor, public methods, private methods), one blank line between
  members inside a group.
- Every file ends with a newline.
- No primary constructors; the team does not use them. Older code in
  `unite-feed-omics` and `unite-indices` still has some, and two files have
  block namespaces; convert them when touching those files.
- Use `var` wherever possible.
- Nullable reference types are **off** (no `<Nullable>enable</Nullable>`, no
  `string?` annotations); the annotations cost more than they help here
  (owner, 2026-10-12). `unite-data-source`, `unite-commands` and Identity's
  test project still enable them; turn it off when touching those projects.
  `?` on value types (`int?`, `bool?`) is normal.

### Sync and async

There is no rule to make everything async: UNITE has few concurrent users per
instance, so async rarely matters for scale (owner, 2026-10-12).

- Use async where the library or API is async (EF Core async queries, HTTP
  clients, Elasticsearch, MongoDB), and then stay async up the call chain.
- Avoid blocking on tasks with `.Result` or `.Wait()` where it can be avoided
  without contortions; older code (e.g. the feeds' index creators) still does
  this.
- Sync code is fine where everything it calls is sync.

### Errors and exceptions

Write code that does not throw; exceptions are for what the code cannot
control (owner, 2026-10-12).

- **Expected outcomes** ("not found", "already exists", invalid input) are
  return values: `null`, `bool` or a result object. The controller maps them to
  `NotFound()`, `BadRequest()` and so on.
- **Exceptions** are for unexpected failures and broken invariants. They reach
  the global `DefaultExceptionFilter`, which logs them (with the stack trace)
  and returns 500. Do not catch them in controllers just to rethrow or hide
  them.
- **Catch a specific exception only to handle it differently**; otherwise do
  not catch at all. Which exception type was thrown rarely matters when it is
  outside our control.
- **Parent code protects child code.** Validate once, as early as possible
  (request validators, then the service entry point), and let the code below
  rely on it instead of checking the same thing again and again.
- In submission processing, invalid data that validation could not catch (e.g.
  a missing parent specimen) throws, so the task fails.

### Dependency injection

- Constructor injection.
- Register in the DI container: controller dependencies, heavier or more complex
  services, services behind abstract classes or interfaces, hosted services and
  options.
- When a helper service is used only in one place, inject its dependencies
  (options, `DbContext` or its factory) instead, and create the helper with
  `new` in the constructor. Example: a repository used only by one service.

### Naming

- Naming is hard; take the time. The namespace is part of the name: prefer
  `...Genes.Expression` and `...Proteins.Expression` over
  `...Genes.GeneExpression` and `...Proteins.ProteinExpression`.
- Prefer short names, and single words where possible, especially for
  namespaces (folders).
- Use **`entity`** for objects from the database, so it is clear where they come
  from: `entity => entity.Name == name`, not `x => x.Name == name`. In general,
  name lambda parameters with understandable words.

### Configuration

Settings are environment variables read by option classes in
`Configuration/Options` (getters, no `IOptions<T>`), registered in DI and
documented in the repository's README.

- **Required** settings throw a clear error when missing, e.g.
  `'UNITE_SQL_HOST' environment variable has to be set`.
- **Optional** settings return a documented default, or `null` when the feature
  is simply off (e.g. SMTP, LDAP, footer links). Do not make them required.

### Data access

- Read with `.AsNoTracking()`; update explicitly with
  `dbContext.Update(entity)` when needed.
- Materialize query results as arrays unless the collection is meant to be
  modified: `dbContext.Set<Type>().AsNoTracking().Where(entity => ...).ToArray()`.

### Collections and types

- Use the right data structure, leaning towards the simplest one the function
  needs. Prefer arrays for collections that are not modified later.
- Do not use `.ToList()` or `List<T>` parameters without a reason; accept the
  simplest type (array or `IEnumerable<T>`) that the method needs.
- Use **records** for data: EF entities (`unite-data`, `unite-identity-data`),
  request and submission models, index documents, resources and other models.
  Use classes for things with behavior: services, repositories, controllers,
  handlers, workers, options. Older models that are classes are converted when
  touched.
- In models, plain properties use `{ get; set; }` so binders, converters and
  EF can assign them. Normalization uses a backing field with a getter
  (`get => _id?.Trim(); set => _id = value;`).
- Records compare by value: do not rely on `Equals` or hash sets to identify
  entities; compare their keys.

### Request models

- Text identifiers and references are normalized to lowercase (see
  [Coding conventions](../AGENTS.md#coding-conventions)), usually in the
  property getters of the request models.
- Decide per field: most values should be trimmed and normalized, some must be
  left exactly as received. Do not normalize blindly.

## Vue 3 (portal)

- Options API.
- Single quotes in new and changed code. The portal still uses mostly double
  quotes; convert gradually where you touch code, not in one large change.
- Register own components with the `U` prefix (`u-data-table` in templates).
- A `settings.js` per module; mixins for shared page behavior; follow the
  existing module structure (see `unite/AGENTS.md`).

## Tests

Use focused tests for meaningful computation or custom behavior. Avoid
exhaustive mocked coverage and tests that mirror the implementation. See
[Development validation](development-validation.md).
