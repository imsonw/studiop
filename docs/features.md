# Feature Inventory — Studiop

Full enumeration of every feature found in the source Flutter app. This is a **definition of what
exists**, not a scope decision — what actually ships in v1 (and in what order) is decided separately;
when that's settled, record it as a scope/priority section in [architecture.md](./architecture.md)
rather than editing this file. Every feature with a network call maps to a `Repository` in
[api-reference.md](./api-reference.md).

## Auth & Account

- **Auth**: register, login, quick login, email verification, password reset (request + confirm)
- **Biometric login**: Face ID/Touch ID, `device_id` + `biometric_token` pairing, enable/disable/check-status
- **Social login**: Google, Apple, TikTok — plus a post-social "collect email" screen when the
  provider doesn't supply one
- **Profile**: view/edit profile, change password, change info (name, contact, social, company, VAT)
- **Address book**: list, create, update, delete, set default, select-address bottom sheet
- **Account deletion**: request with a reason, confirm via emailed code
- **Account verification** flow (separate from email verification at registration)
- **Feature-flag toggle screen** — a dev/QA tool for flipping Forum/Marketplace flags, not an
  end-user feature

## Home / Dashboard

- Home tab: statistics strip, home banners/slides, quote/review block, live-stream list + category
  filter, "hot products" section, lucky-wheel studio carousel, quick actions, per-platform
  (TikTok/etc.) filter section
- Welcome/onboarding screen
- Bottom tab shell: Home / Live / Store / Forum (flag-gated) / Order / Account

## Live viewing & bidding (viewer side)

- Live list + filter (by category/platform)
- Live room: multi-CDN video playback — one player per source (native RTMP, TikTok, Twitch, YouTube,
  Castr)
- Live chat — Firebase-backed for in-app streams, REST-polling fallback for web/social streams
- Reactions overlay (heart/flower)
- Bid list overlay + top-bidder leaderboard (read-only, computed server-side)
- "Now selling" product overlay / waiting state
- Per-platform live viewer count badges
- "Coming soon" pre-live modal: countdown, shop stats, media gallery, CTA button

## Streaming (seller/broadcaster side)

- RTMP camera broadcast start/stop
- Toggle "selling" on/off mid-stream
- Attach a product to sell mid-stream
- Resume an in-progress stream on a new device, or resume a stream started on web
- Network-instability detection during broadcast
- Streamer-side bidder list
- Confirm-stop-live / confirm-stop-selling / confirm-web-session modals
- Image upload for stream/product

## Store / Catalog

- Storefront tab, category browse, product list per category
- Product detail: image carousel, seller card, tiered pricing, reviews, related products
- Search: autocomplete, recent searches, suggested products
- Brand listing
- Favorite / followed shops
- Flash sale list
- "Today's suggestion" section
- Home-content zones (mall banners/zones/slides)
- Studio/shop page: tabs for catalog, live, products, shop info — ties into the live viewer badge

## Cart & Checkout

- Cart: add / update / remove / clear / count, tiered-price add-to-cart bottom sheet
- Checkout: address selection, payment method, order creation, success screen
- "Buy now" (checkout without adding to cart first)

## Orders

- Order list with status filter/search
- Order detail: shipping/payment/voucher/invoice cards, status banner
- Invoice PDF viewer
- Voucher code redemption

## Payment

- Mollie payment via in-app WebView, redirects back into order detail on completion

## Reviews

- Write review: star rating, photo/video upload, per line-item review
- View reviews: product reviews (rating filter, media gallery), store/shop review stats
- "My reviews": not-yet-reviewed vs. reviewed tabs

## Mini-games

- **Lucky Wheel**: per-studio spin wheel, prize modal, intro/product-detail modals tied to prizes
- **Blackjack**: full card game (self-contained package in the source app), stats + score recording —
  its entry point is currently disabled in the source app's home tab (built, not exposed)

## Chat & Notifications

- Support/order chat (Ably-backed): conversation list, thread view, image/video/document attachments,
  order-context card, "order support" quick action, connection-status indicator, read/active-state
  sync
- Push notifications (FCM): topic-based (public / per-platform / per-user), tap-through to detail,
  in-app notification list

## Community — feature-flagged off by default in the source app

- **Forum**: category feed, post detail + threaded comments, create post (topic/subtopic), reactions,
  user's own forum profile (posts/comments/media tabs)
- **Marketplace**: location-based classifieds — category / for-you / local tabs, multi-step listing
  creation, deal/offer negotiation, message-seller, user's own listings + saved items

## Known-incomplete in the source app — carry the limitation over, don't silently "complete" them

- **News**: a single detail screen, backed by mock data only — no real endpoint exists yet
- **Hot Products** section on Home: mock data only, no endpoint wired up yet

If either of these needs a real backend, that's a new API to design with the backend team — it's not
in api-reference.md because the source app doesn't call anything real for it either.
