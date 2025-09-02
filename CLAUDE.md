# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

StarOracle (星谕) is a hybrid React + iOS native app that creates an interactive constellation of personal questions and AI-generated answers. Users click on empty space to ask questions, which become "stars" connected by thematic relationships.

**Tech Stack**: React 18, TypeScript, Vite, Capacitor, Tailwind CSS, Zustand, Framer Motion, Swift (iOS native components)

**Architecture**: Hybrid approach with React web components + iOS native Swift components for enhanced UX

## Development Commands

**Web Development**:
- `npm run dev` - Start Vite dev server (localhost:3000)
- `npm run build` - TypeScript check + production build to dist/
- `npm run preview` - Preview production build locally

**iOS Development** (requires user confirmation for npm/npx commands):
- Build and run iOS: `npm run build && npx cap sync ios && sleep 3 && osascript -e 'tell application "Xcode" to activate' -e 'tell application "System Events" to keystroke "r" using {command down}'`
- Sync native assets: `npx cap sync ios`
- Open in Xcode: `npx cap open ios`

## Project Structure

- **src/components/** - React UI components (PascalCase files)
- **src/hooks/** - Custom React hooks, including native component integration
- **src/store/** - Zustand state management (`useStarStore.ts`, `useChatStore.ts`)
- **src/utils/** - Utility functions (AI interactions, sound, templates, etc.)
- **src/plugins/** - Capacitor plugin definitions for native bridge
- **src/types/** - TypeScript type definitions
- **ios/App/App/** - iOS native Swift components (`InputDrawerManager.swift`, `ChatOverlayManager.swift`)

## Key Architecture Patterns

**Hybrid Component Strategy**: Many features have both React and Swift native versions. When both exist, prioritize the native Swift version for iOS platform:
- InputDrawer: React (`ConversationDrawer.tsx`) + Native (`InputDrawerManager.swift`)  
- ChatOverlay: Native only (`ChatOverlayManager.swift`)
- Most UI components: React only

**State Management**: 
- `useStarStore.ts` - Global constellation state, star data, UI state
- `useChatStore.ts` - Chat/conversation state
- Native-React bridge via custom hooks (`useNativeInputDrawer.ts`, `useNativeChatOverlay.ts`)

**Capacitor Plugin Pattern**: Custom native functionality exposed via Capacitor plugins with TypeScript definitions in `src/plugins/`

## Important Guidelines

**Language**: Always respond in Chinese (中文)

**Code Standards**: 
- Never create simplified versions - implement full functionality
- Follow existing patterns and conventions
- Import alias: Use `@/` for src/ paths (configured in vite.config.js)
- Components: PascalCase, hooks: useSomething, stores: somethingStore

**User Interaction Protocol**:
- When user refers to components/features, check `功能索引.md` first to identify exact files/modules
- Confirm before running any npm/npx commands
- Follow 4-step problem solving: analyze → confirm cause → plan → solve

**Native Priority**: For features with both React and native implementations, default to modifying the native Swift version

**Audio Feedback**: Use `say` command to announce task completion: `say "{task name}完成"`

**Testing**: No formal test suite - verify by building (`npm run build`) and manual testing in dev/iOS

## Core Features Map

Refer to `功能索引.md` for detailed component-to-file mappings. Key areas:
- **Constellation interaction** (`src/components/Constellation.tsx`) - Main star field, click handling
- **Input system** - Dual React/Native implementation 
- **Star details** (`src/components/StarDetail.tsx`) - Individual star information panels
- **Collections** (`src/components/StarCollection.tsx`) - Star browsing/management
- **AI configuration** (`src/components/AIConfigPanel.tsx`) - API key management