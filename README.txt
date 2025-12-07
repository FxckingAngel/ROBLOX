Korone Studio Tools (2026 multi-file build)
==========================================

Credit:
  - Original Dex concept + layout by Moon.
  - This build is a reimagined, modernized studio-style toolkit by Korone + ChatGPT.

Files:
  - main.lua         -> bootstrap loader (run this)
  - KS_Util.lua      -> decompiler, decomposer, saveinstance helper
  - Editor.lua       -> live script + property editor
  - Explorer.lua     -> game explorer (double-click opens editor)
  - RSpy.lua         -> remote spy (FireServer / InvokeServer)
  - SecretPanel.lua  -> secret executor/console panel
  - ModelViewer.lua  -> simple 3D viewport for instances
  - Hub.lua          -> emoji hub (🌙) pinned on the left side of the screen

How to install:
  1. Put the entire `KoroneStudio` folder into your executor's workspace/scripts folder.
  2. Make sure all .lua files stay inside that folder (do not rename them).
  3. Execute `main.lua` from your executor.

Features:
  - Live script editing with save + export-to-file.
  - Property editing for common fields.
  - Better decompiler flow:
      * Uses `decompile` if your executor has it.
      * Falls back to script.Source.
      * Or bytecode dump using `getscriptbytecode`.
  - Explorer + JSON export of any instance tree.
  - Binary SaveInstance helper (if your executor exposes `saveinstance`).
  - Remote spy using `hookmetamethod` + `__namecall` (if supported).
  - Secret console panel that runs custom code and captures print().
  - Basic 3D model viewer using a ViewportFrame.

Notes:
  - Not every executor supports every feature:
      * Filesystem: needs `readfile`, `writefile`, `isfolder`, `makefolder`.
      * SaveInstance: needs `saveinstance`.
      * Remote spy: needs `hookmetamethod` + `getnamecallmethod`.
  - If something errors, check the output window in your executor.

Usage:
  - After running main.lua you’ll see a small 🌙 toolbar on the left:
      * 🗂 opens Explorer
      * ✏️ opens Editor for current Studio selection
      * 📡 toggles Remote Spy
      * 🕵️ opens Secret Service Panel
      * 🧊 opens 3D Model Viewer

