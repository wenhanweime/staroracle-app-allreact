# Repository Guidelines
## 总是用中文回复
## 完成之后，运行 npm run build && npx cap sync ios && sleep 3 && osascript -e 'tell application "Xcode" to activate' -e 'tell application "System Events" to keystroke "r" using {command down}'
## 完成之后，使用 bash中的 say  修改完成

## Project Structure & Module Organization
- `src/`: App code (React + TS). Key folders: `components/` (UI, PascalCase files), `hooks/` (custom hooks), `store/` (Zustand stores), `utils/`, `types/`, `plugins/`. Entry: `main.tsx`, `App.tsx`.
- `public/`: Static assets copied as‑is.
- `ios/`: Capacitor iOS native project (open in Xcode).
- `dist/`: Production build output (generated).
- `docs/` and `doc/`: Project documentation and references.
- Config: `vite.config.js` (alias `@ -> src`), `tailwind.config.js`, `capacitor.config.ts`, `tsconfig*.json`.

## Build, Test, and Development Commands
- `npm run dev`: Start Vite dev server at `http://localhost:3000/`.
- `npm run build`: Type‑check (`tsc`) and build production bundle to `dist/`.
- `npm run preview`: Serve the `dist/` build locally for verification.
- iOS (Capacitor): `npx cap sync`, then `npx cap open ios` to build/run in Xcode.

## Coding Style & Naming Conventions
- TypeScript + React function components, 2‑space indentation.
- Components: PascalCase (e.g., `StarCard.tsx`) in `src/components`.
- Hooks: `useSomething.ts` in `src/hooks`.
- Stores: `somethingStore.ts` (Zustand) in `src/store`.
- Utilities/types: `camelCase.ts`, `PascalCase.d.ts` in `src/utils` and `src/types`.
- Imports: prefer alias `@/…` (e.g., `import { Foo } from '@/components/Foo'`).
- Tailwind for styling; colocate small component styles in the component file.

## Testing Guidelines
- No formal test suite yet. Before PRs: build locally, exercise critical flows in dev/preview, and smoke test the iOS app via Xcode.
- Suggested future setup: Vitest + React Testing Library; name tests `*.test.ts(x)` mirroring source paths.

## Commit & Pull Request Guidelines
- Commits: concise imperative subject; prefixes like `feat:`, `fix:`, `chore:` are welcome. Descriptions may be in English or Chinese; emojis are acceptable when meaningful.
- PRs: include summary, rationale, screenshots for UI changes, and any related issue IDs. Note any platform (iOS/web) impacts.
- Ensure `npm run build` passes and docs/config samples (`.env.local.example`) are updated when config changes.

## Security & Configuration
- Secrets: use `.env.local`; never commit real secrets. Update `.env.local.example` when adding new vars.
- iOS signing and provisioning are managed in Xcode; do not commit personal signing assets.
