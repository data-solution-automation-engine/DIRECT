# Migration Tests

This folder contains tests and assets for verifying database migrations.

- `PreviousVersion/`: Contains the previous version's DACPAC and deploy scripts.
- `MigrationTestData/`: SQL scripts to seed the database before migration.
- `MigrationTests.cs`: Test class for migration scenarios.

## How it works

1. Deploy the previous version DACPAC.
2. Run pre/post deploy scripts for the previous version.
3. Seed the database with test data.
4. Deploy the current version DACPAC (built from the database project).
5. Run pre/post deploy scripts for the current version.
6. Assert that the migration succeeded and data is as expected.
