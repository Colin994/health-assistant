# Health Assistant workspace instructions

For every change that can affect the Android or iOS app, read [the cross-platform design and walkthrough contract](quality/mobile-design-and-walkthrough.md) first. This includes UI, navigation, business logic, data, permissions, native integrations, build settings, and mobile tests. The contract applies to all future changes, regardless of design source or conversation history.

- Use the same approved design revision, shared Flutter UI and tokens, and [walkthrough cases](quality/mobile-walkthrough.json) for Android and iOS. A platform-specific behavior must be documented against the same case, with its reason and expected result.
- Verify design approval for the affected screen and state in [the design baseline](quality/design-baseline.md). Use [design proposals](quality/design-proposals/) for candidate work. A Pixso page name, version label, frame ID, or screenshot alone is insufficient evidence of approval.
- For interface or interaction changes, identify the reviewed revision for the affected scope before implementing it. If the required approval or revision is missing, report it as pending and continue work that does not depend on it. For changes that preserve the interface and interactions, use the applicable baseline and continue implementation and tests even when the design reference still needs to be recorded. Report that gap in the handoff.
- Separate code checks, simulator checks, and physical-device results. Report Android and iOS independently. Claim cross-platform acceptance only when both physical-device runs meet the contract.
- Apply these rules even when starting without previous conversation history.
