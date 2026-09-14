# FanMTL Fixed — Shosetsu repository

This is a small third-party Shosetsu repository containing a fixed FanMTL extension.

## What is fixed

- Changes the obsolete `fansmtl.com` base URL to `fanmtl.com`.
- Changes listing URLs to `fanmtl.com`.
- Adds a title-to-slug fallback for search because the old FanMTL `/e/search/` endpoint returns 404.
- The fallback can directly resolve titles such as:
  `I am just an adopted son, sisters, please stop bothering me`

## Install

Upload the contents of this folder to a GitHub repository with GitHub Pages enabled.

Then add this URL in Shosetsu > More > Repositories:

`https://YOUR-USERNAME.github.io/YOUR-REPOSITORY/`

The URL must expose `index.json` at its root.

The existing Shosetsu repository guide explains this format:
https://shosetsu.app/help/guides/repositories.html
