# Security policy

## Supported versions

Only the latest version on the App Store receives security fixes.

## Reporting a vulnerability

Please do not open a public issue for security problems.

Report it privately through GitHub: open the **Security** tab of this repository and click **Report a vulnerability**. Include:

- the app version and iOS version
- steps to reproduce, or a proof of concept
- the impact you expect, such as token leakage or data exposure

## What happens next

The project is maintained by Andrea Grandi, who handles all security reports.

- I will acknowledge your report within 7 days.
- I will confirm whether the issue is valid and share a plan for a fix within 14 days.
- Once a fix is released, I will publish a GitHub security advisory and credit you, unless you prefer to stay anonymous.

Please give me 90 days to release a fix before you disclose the issue publicly.

## Scope

In scope: code in this repository and the app builds published from it.

The server and API at bookcorners.org live in [andreagrandi/book-corners](https://github.com/andreagrandi/book-corners). Report server-side issues there.

Out of scope: issues that need a jailbroken device, automated scanner output without a working exploit, social engineering, and issues in third-party services or dependencies that are not caused by how this project uses them. Please report those to the upstream project.

Do not access or change other users' data while testing. Use your own accounts.

