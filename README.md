# Hey Buddy

Hey Buddy is a dark-themed, Instagram-style social media app: posts, 24-hour
stories, likes, comments, saved posts, public/private profiles with follow
requests, hashtag search, and direct messages.

## Status

The current build (`hey-buddy.html`) is a front-end prototype. It runs
entirely in the browser and stores data in `localStorage`, so content is not
shared between users yet. `heybuddy_schema.sql` is the MySQL database design
for the real, multi-user backend this project is moving towards.

## Files

- `hey-buddy.html` — the working front-end prototype (HTML, CSS and
  JavaScript in a single file). Open it in a browser to try the app.
- `heybuddy_schema.sql` — the MySQL schema for the planned backend.

## Database design

The schema has eleven tables:

- **users** — accounts, with a hashed password, bio, avatar, and a
  `is_private` flag for private profiles.
- **posts** — user posts, with caption, media, and a soft-delete flag
  (`is_deleted`) so removed posts can be audited rather than lost outright.
- **stories** — posts that expire after 24 hours, via an `expires_at`
  timestamp.
- **follows** — who follows whom. The same table also holds pending follow
  requests for private accounts, distinguished by a `status` column
  (`pending` or `accepted`), rather than needing a second table.
- **likes** — a single table for likes on both posts and stories, using a
  `target_type` / `target_id` pair instead of duplicating the table per
  content type.
- **comments** — comments on posts.
- **saved_posts** — a user's bookmarked posts.
- **hashtags** and **post_hashtags** — tags are stored once and linked to
  posts through a join table, so searching by tag is a fast indexed lookup
  rather than a text scan of every caption.
- **conversations** and **messages** — direct messages between two users.
- **notifications** — likes, comments, follows, and follow requests that
  should appear in a user's activity feed.

### Design choices worth noting

- Every table uses an auto-incrementing `BIGINT UNSIGNED` primary key, and
  every relationship is enforced with a foreign key with `ON DELETE CASCADE`,
  so deleting a user cleanly removes their dependent data instead of leaving
  orphaned rows.
- Indexes are placed on the columns that will actually be queried or sorted
  often — a user's posts by date, a conversation's messages by time, a
  user's notifications by date — rather than indexing everything.
- `UNIQUE` constraints prevent duplicate data at the database level, not just
  in application code: a user can't like the same post twice, can't follow
  the same person twice, and two users can't end up with two separate
  conversation threads.
- Passwords are stored only as `password_hash` — the schema never has a
  column for a plain-text password.

## Roadmap

- Stand up a real backend (planned: Supabase) so posts, follows, and
  messages work between real, separate user accounts.
- Wire the existing front end to that backend instead of `localStorage`.
- Add notifications and follow-request approval as real, working screens.
