# ADR 007: Accessibility Strategy

## Status
Accepted

## Context
Sayr must be accessible to all users, including those with visual impairments or motor disabilities.

## Decision
Target **WCAG 2.1 Level AA** compliance:

- Semantic labels on all interactive elements
- Focus management on all forms
- Screen reader testing per release
- High contrast mode support

## Implementation
- `Semantics` widget wrapper for custom components
- `FocusTraversalGroup` for form navigation
- `MediaQuery` checks for `highContrast` and `disableAnimations`
