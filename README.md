# ballardian.ai

Essays, threads and a page on the life and work of J.G. Ballard.

- `index.html` is the whole site: markup, styles and script in one file.
- `collage.jpg` is the background, composed from Ballard book jackets.
- `schema.sql` is the database: tables, access rules and triggers for Supabase.
- `CNAME` tells GitHub Pages to serve the site at ballardian.ai.

## How it runs

The page is static and hosted on GitHub Pages. Accounts, essays, threads and votes
live in a Supabase project. The two values at the top of the script in `index.html`
(`supabaseUrl`, `supabaseAnonKey`) connect them. With those left empty the site runs
in preview mode, where posts are saved only in the visitor's own browser.

Who can do what is enforced in the database, not in the page:

- Anyone can read essays and threads.
- Signed-in members can start threads, reply and vote.
- Writers can publish essays. Admins make members into writers from the account page.
- Admins can remove any post.

Sign-in is by emailed link. Signing in with X, or linking an X account afterwards,
is optional and shows the member's X handle beside their name.

## Changing the site

Edit `index.html` and push to `main`. GitHub Pages republishes within a minute or so.
