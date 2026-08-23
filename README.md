A cross-platform mobile engineering playground.

Implementing the same GitHub features with:

Flutter         █
Jetpack Compose █
SwiftUI         
React Native    

## Features

| Feature | Flutter | Compose | SwiftUI | RN |
|---------|---------|---------|---------|----|
| App Shell | 🚧 | ⬜ | ⬜ | ⬜ |
| Home | 🚧 | ⬜ | ⬜ | ⬜ |
| Search | 🚧 | ⬜ | ⬜ | ⬜ |
| Repository Detail | ⬜ | ⬜ | ⬜ | ⬜ |
| Code Browser | ⬜ | ⬜ | ⬜ | ⬜ |
| Issue | ⬜ | ⬜ | ⬜ | ⬜ |
| Pull Request | ⬜ | ⬜ | ⬜ | ⬜ |
| Diff Viewer | ⬜ | ⬜ | ⬜ | ⬜ |
| User Profile | ⬜ | ⬜ | ⬜ | ⬜ |
| Notification | ⬜ | ⬜ | ⬜ | ⬜ |
| Authentication | ⬜ | ⬜ | ⬜ | ⬜ |

- Each feature must go through the following steps:
```
Product
   ↓
Design
   ↓
Backend / API
   ↓
Implementation
   ↓
Benchmark
```

## Principles

The project explicitly avoids forcing all four frameworks into a single shared architecture. Instead, each implementation should follow the conventions and recommended practices of its own ecosystem (e.g., Flutter uses its officially recommended architecture, Compose uses ViewModel, etc.). What stays invariant is the product behavior and feature scope — this is what makes the cross-framework comparison meaningful.