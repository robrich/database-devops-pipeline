A Database DevOps Pipeline
==========================

[![Build Database](https://github.com/robrich/database-devops-pipeline/actions/workflows/build-database.yaml/badge.svg)](https://github.com/robrich/database-devops-pipeline/actions/workflows/build-database.yaml)

This is the companion code to the talk ["A Database DevOps Pipeline"](https://robrich.org/slides/database-devops-pipeline/).  This code sample demonstrates a Database DevOps Pipeline.


About Database Migrations
-------------------------

When building a Database DevOps pipeline, we choose between two main methodologies for changing the database schema:

- State-based:  Each file represents a database schema item: a table, a stored procedure, a view, etc.  These files change over time.  An engine then compares the scripts folder with the database schema, infers the changes, and updates the database to match.

- Migrations-based:  Each file represents all the changes necessary for one adjustment.  A file may include adding a column, changing data, creating a table, etc.  The engine notices which scripts already ran, and run the new ones.

Which approach should you use?  Your preferences and needs may vary, so either can be an effective solution.


Tools used
----------

I definitely don't want to legislate a particular tool.  Look to https://robrich.org/slides/database-devops-pipeline/#/30 for a large but hardly exhaustive list of database migration tools -- some state-based, some migrations-based.  Click through each of the blue links to find one that works for you.  Or use this list to search for others and discover the tool that matches your preferences.

Your tool choice is likely different than mine, but for the sake of the demos, I must choose one.  In this repository I've chosen [SQL Source Control](https://www.red-gate.com/products/sql-development/sql-source-control/) for state-based builds and [Flyway](https://flywaydb.org/documentation/getstarted/firststeps/commandline) for migrations-based builds.  You can use the principles demonstrated here with any toolchain in a Database DevOps Pipeline.


Build Files
-----------

**Note**: In this repository are many builds.  In a real scenario you'd never use all of them.  As you're developing your solution, pick the one you want and delete the rest.

1. `state-based/build.ps1`: On-prem state-based build.  Generate the sql-scripts folder with [SQL Source Control](https://www.red-gate.com/products/sql-development/sql-source-control/).  This build could be run by a Windows build agent from Jenkins, TeamCity, or any build system in your infrastructure.

2. `state-based/build.sh`: On-prem state-based build.  This moves the content from PowerShell to bash.  This could be run from a Linux build agent from a build system in your company.

3. `.github/workflows/state-based-interim.yaml`: Cloud-native state-based build.  This is the first step in moving from on-prem to cloud.  Alternatively, one could call build.sh from the cloud build script.

4. `.github/workflows/state-based.yaml`: Cloud-native state-based build.  This leverages containers to build in the cloud and deploy to cloud infrastructure.  GitHub Actions Secrets define the target database, so no secrets are checked into source control.  Generate the sql-scripts folder with [SQL Source Control](https://www.red-gate.com/products/sql-development/sql-source-control/).

5. `migrations-based/build.sh`: On-prem migrations-based build.  This build could be run by a Linux build agent from Jenkins, TeamCity, or any build system in your infrastructure.  Generate the sql folder with any text editor following the [Flyway](https://flywaydb.org/documentation/getstarted/firststeps/commandline) conventions.

6. `.github/workflows/migrations-based.yaml`: Cloud-native migrations-based build.  This leverages containers to build in the cloud and deploy to cloud infrastructure.  GitHub Actions Secrets define the target database, so no secrets are checked into source control.  Generate the sql folder with any text editor following the [Flyway](https://flywaydb.org/documentation/getstarted/firststeps/commandline) conventions.


License
-------

License: MIT
