# WorkFlow 

**WorkFlow** is a minimalist, high-performance offline-first OJT (On-the-Job Training) Management and Time Card tracking application. Built with modern UI interactions, it replaces physical timesheets and outdated biometric tracking by offering users a seamless, interactive grid to log their shifts efficiently.

## Why is it Useful?

Tracking daily hours across Morning, Afternoon, and Overtime shifts can be tedious and prone to calculation errors. HourFlow is extremely useful because it:

- **Eradicates Math Errors**: Automatically calculates **Daily Totals** and **Monthly Accumulated Hours** precisely on the fly handling specific boundaries and overlapping shifts.
- **Offline By Default**: Operates entirely offline without needing an internet connection. Your data resides securely on constraints within your native device memory.
- **Interactivity**: You can instantly fix or log missed time punches strictly by tapping on the Interactive Biometric `Table Grid`.
- **Beautiful UI**: Designed with a sleek, weightless "Antigravity Theme", utilizing transparent Glassmorphism elements for extremely readable visual aesthetics.

## Tech Stack

HourFlow was constructed using industry-leading mobile technologies utilizing a clean **MVVM Architecture**:

*   **Flutter** - The primary UI toolkit for compiling native applications from a unified codebase.
*   **Dart** - The core object-oriented language driving application logic.
*   **Hive** - A lightweight and blazing-fast key-value NoSQL database functioning as the offline-first application memory constraint.
*   **Provider** - Industry-standard Reactive State Management hooking data payloads into the UI safely.
*   **GoRouter** - Declarative framework handling persistent programmatic routing explicitly enabling flawless Bottom Navigation Bars.
*   **Table Calendar** - Beautiful Material 3 compliant Calendar hook orchestrating monthly layout representations.

## Core Features

1. **Biometric Time Card Grid**: A completely locked Data Table simulating physical structural timecards displaying exactly 31 trailing days seamlessly natively.
2. **Dynamic Log Forms**: Supports multi-column log hooks parsing specific blocks like `(AM In/Out, PM In/Out, Overtime In/Out)`.
3. **Reactive Summaries**: Monthly data dynamically computes trailing totals yielding exact hours worked.
4. **Instant Action Hot-Hooks**: Secure long-press capabilities rapidly wipe inaccurate records from the history securely via Modal barriers.
5. **Dark Mode Integration**: Naturally fluid and battery-efficient themes optimized completely seamlessly.

---

*Project developed exclusively for optimized Time Tracking precision.*
