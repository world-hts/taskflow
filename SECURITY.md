# Security and privacy notes

- TaskFlow has no network client, remote database or authentication flow.
- Task data is stored locally using `shared_preferences` and is not encrypted. Do not use this storage for passwords, tokens, or highly sensitive information.
- The starter data is fictional and contains no user information.
- Validate task titles in the editor and controller before saving.
- Review dependency advisories with the Dart/Flutter package tooling when dependency versions are updated.

## Reporting

For this portfolio project, open an issue in the repository describing the affected version and reproduction steps. Do not include private task data in issue reports.
