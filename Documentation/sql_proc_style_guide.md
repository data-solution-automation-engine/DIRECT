# SQL Procedure Documentation and Style Guide

This guide provides consistent conventions and best practices for documenting and writing SQL Server stored procedures within the DIRECT Framework.

## Overview

Applies to:

- SQL Server stored procedures
- DIRECT Framework conventions
- JSDoc-style annotations in comment blocks

---

## 1. File Header Format

Each procedure must begin with a structured comment block using `/** */` syntax. This comment block documents the procedure for automated parsing and developer reference.

### Example

```sql
/**
 * @procedure [schema].[ProcedureName]
 * @description
 *   One-line summary.
 *   Optionally add extended multi-line description.
 *
 * @package <package name>
 * @version <semantic version>
 * @see <reference or URL>
 *
 * @param {<TYPE>} @ParamName  [in|out] (optional|required, default=...)
 *   Description.
 *
 * @returns {<TYPE>} Description of return code or value.
 * @resultset Description or "none"
 *
 * @lineage
 * - reads:
 *     object1, object2
 * - writes:
 *     object1, object2
 *
 * @example
 * DECLARE ...
 * EXEC ...
 */
```

---

## 2. Parameters

### Declaration Block

Group and comment parameters in the procedure signature:

```sql
CREATE PROCEDURE [schema].[ProcName]
(
  /* Required parameters */
  @RequiredParam NVARCHAR(100),

  /* Optional parameters with defaults */
  @OptionalParam INT = 0,

  /* Output parameters */
  @OutputParam NVARCHAR(MAX) OUTPUT
)
```

### Formatting Guidelines

- Align data types and assignment operators where feasible.
- Avoid forcing alignment if it causes excessive line length.
- Break long comments into separate indented lines under the parameter.

### JSDoc @param Tags

```sql
 * @param {NVARCHAR(100)} @ExampleParam  [in] (required)
 *   Description of parameter.
```

- Always lowercase `in`, `out`, and `optional`/`required`.
- Keep type in uppercase (`INT`, `NVARCHAR(MAX)`, etc.).

---

## 3. Logging and Debugging

- Use `@Debug`, `@MessageLog`, and `@SuccessIndicator` consistently.
- Normalize Y/N flags via `UPPER(TRIM(...)) = 'Y'`.
- Add procedure name and version to `@MessageLog`.
- Add start and end timestamps and run duration.

---

## 4. Error Handling

- Use `TRY...CATCH` for all main operations.
- Use `@ThrowOnFailure` to optionally throw on error.
- Standard error handling must:
  - Set `@SuccessIndicator = 'N'`
  - Log error details using `AddLogMessage`
  - Insert to `[omd].[InsertIntoEventLog]`

---

## 5. Lineage and Metadata

- Use `@lineage` block to document read/write dependencies.
- Always qualify names with schema.
- Use lowercase `reads:` and `writes:` labels.
- List functions, tables, procedures explicitly.

---

## 6. Examples

- Provide full `@example` section with:
  - Valid example parameter declarations
  - Procedure call
  - Output handling (PRINT or SELECT)

---

## 7. Return Codes

- Document `@returns` clearly with meanings.
- Use `RETURN @ReturnCode;` consistently.
- Use:
  - `0` = success
  - `-1` = validation or logical failure
  - `-2` = system/try-catch error

---

## 8. Capitalization and Terminology

- Prefer lowercase terms for `in`, `out`, `optional`, `required`, `reads`, `writes`, `resultset`.
- Prefer Title Case for log labels and user-visible message strings.
  - Example: `'Processing Error'`, `'Parameter @BatchCode'`
- Keep function and table names in square brackets, fully qualified where relevant.

---

## 9. General SQL Style

- Always use `BEGIN ... END` blocks for multi-statement logic.
- Use `SET NOCOUNT ON;` and `SET XACT_ABORT ON;` at the top of the procedure.
- Use `SYSUTCDATETIME()` for time tracking.
- Prefer `CONCAT` over `+` for string building.
- Avoid SELECT \* in production logic, but allowed in log messages.
- Use `GOTO EndOfProcedureSuccess/Failure` for clear control flow.

---

## 10. Message Log Conventions

- Levels: `DEBUG`, `INFO`, `ERROR`, `SUCCESS`, `CRITICAL`
- Wrap logs in `IF @ProcessMessageLog = 'Y'` blocks.
