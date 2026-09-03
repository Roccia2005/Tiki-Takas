# Tiki-Takas Dev Rules
- Engine: Godot 4.7.2 Headless. Indentation: Hard Tabs (\t).
- Architecture: Pure data in `scripts/resources/`, pure logic in `scripts/core/`. No Node2D/UI.
- Token Saver: Keep terminal outputs minimal. Only print failed assertions or errors during tests.
- Response style: Be concise. Summarize changed files, list test results, show commit hash. Avoid chatting.