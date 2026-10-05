# Security Policy

![Responsible private security reporting](previews/section-security.webp)

**Protect the apps that depend on this package. Report sensitive findings privately.**

If a defect in `flutter_carplay` could expose information, cross a trust boundary or enable an action the application did not authorize, a clear private report is the best place to start.

## Where to report

[Open a private vulnerability report on GitHub](https://github.com/oguzhnatly/flutter_carplay/security/advisories/new), or email [info@oguzhanatalay.com](mailto:info@oguzhanatalay.com) with the subject `flutter_carplay security report`.

Do not publish an undisclosed vulnerability, exploit or sensitive log in a public issue or pull request. Ordinary defects without a security impact belong in the [issue tracker](https://github.com/oguzhnatly/flutter_carplay/issues).

## What to include

Provide the affected package version, platform and host configuration; a description of the impact; and minimal steps to reproduce the issue safely. Include the conditions required to exploit it and a suggested mitigation if you have one.

Use test data and an application you are authorized to examine. Remove credentials, signing material, account information and personal recordings from attachments. Do not test against another person's account, application or vehicle without permission.

## Response and disclosure

The maintainer's response target is **48 hours to acknowledge a report**, with a target of **7 days for a critical fix**. Reproduction, platform requirements and the scope of a remediation can affect those targets; they are not a guarantee that every report will be resolved in that period.

After triage, coordinate a fix or mitigation, its verification and the disclosure date through the private report. Discuss appropriate credit there too. Give users an opportunity to receive the fix before publishing exploit details.

## Releases and integration boundaries

Security fixes prioritize the current stable release, **1.7.x**. Reports affecting earlier releases are welcome; identify the exact affected versions. Backports are assessed during triage. Releases earlier than 1.1 are not supported.

The package supplies the template bridge. Applications still own authentication, data access, remote image sources, permissions and any media or speech service they integrate. The bundled Android Auto service's permissive host validator is not a production host allowlist; review the README's host-validation guidance before distribution.

CarPlay entitlement approval and successful template presentation do not replace application-level authorization or a security assessment of those integrations.

Thank you for helping maintain a dependable foundation for Flutter's in-car applications.
