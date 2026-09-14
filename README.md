# FanMTL Fixed Shosetsu repository

Repository root is intended to be usable through GitHub raw hosting.

Important: this extension fixes the obsolete `fansmtl.com` domain and bypasses
FanMTL's legacy search endpoint, which currently returns 404.

The search fallback converts a title into FanMTL's current `/novel/<slug>.html`
URL. For example:

I am just an adopted son, sisters, please stop bothering me

becomes:

/novel/i-am-just-an-adopted-son-sisters-please-stop-bothering-me.html
