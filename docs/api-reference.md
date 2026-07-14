# API Reference — Backend

Source of truth for every network call the iOS app needs to reproduce. Extracted from the current
Flutter client's service layer and config file. Cross-check against the backend team before
finalizing a contract — this was reverse-engineered from client code, not an official spec.

Each table row maps 1:1 to a method on the suggested `Repository` protocol so implementation can
follow this file directly.

## Base configuration

The domain/host below is the **only** place it should ever appear — keep it inside a single
`Environment` value in Core, never inlined into a Repository or a view. That's what makes pointing
at a self-built backend later a one-line change instead of a search-and-replace.

```
staging: https://staging.<current-backend-domain>/api
prod:    https://service.<current-backend-domain-alt>/api
```
(see the Flutter client's `lib/config.dart` for the literal current values)

Both may be overridden at runtime via Firebase Remote Config (keys like `api_domain_staging`) —
model this as an `Environment` that can be re-resolved after a remote-config fetch, not a compile-time
constant.

Firebase Realtime Database URL: also a single value in the same `Environment` (see the Flutter
client's `lib/config.dart` for the literal current staging/prod URLs).

## Auth mechanism (must replicate exactly)

- Every request carries the token as a **query parameter** `?token=...` — NOT an `Authorization`
  header. Anonymous/public endpoints use a shared public token (`Xo0otTOevqxS4f6Vv1aGrcTfr6T5aUk5`,
  same value in both environments); authenticated endpoints use the logged-in user's token.
- A `lang` header is sent with every request (current locale).
- A `device_fw` query param is attached to every request (device platform code).
- On 401/403, or a 200 response body containing an invalid/expired/unauthorized token message: clear
  local session and force navigation to login. **There is no refresh-token endpoint** — the token is
  long-lived and non-refreshable; re-login is the only recovery path. Do not invent a refresh flow.
- Token + cached profile are stored locally (Flutter: SharedPreferences keys `token` / `user_info`) —
  iOS equivalent: Keychain for the token, lightweight cache for the profile.
- Biometric login is a separate mechanism: a `device_id` is paired with a `biometric_token` via
  `/v1/biometric/enable`, then exchanged for a session at `/v1/biometric/login` using the public
  token (no user token needed for that call).

---

## `AuthRepository`

| Method | Path | Body / Query | Notes |
|---|---|---|---|
| POST | `/users/register` | registration fields | |
| POST | `/users/login` | `{email, password}` | |
| POST | `/users/verify/account` | `{email, code}` | email deep-link activation |
| POST | `/users/reset/password` | `{email}` | |
| POST | `/users/reset/password/confirm` | `{email, reset_token, new_password, new_password_confirmation}` | |
| POST | `/users/socials` | `{social, social_token, social_email?, social_user_id?, social_name?, social_avatar?, auth_code?, code_verifier?, redirect_uri?}` | Google / Apple / TikTok |

External (not backend): `GET https://oauth2.googleapis.com/tokeninfo?id_token=...`

## `BiometricRepository`

| Method | Path | Body / Query | Notes |
|---|---|---|---|
| POST | `/v1/biometric/enable` | `{device_id, device_name}` | |
| POST | `/v1/biometric/disable` | `{device_id}` | |
| GET | `/v1/biometric/check-status` | `?device_id=` | |
| POST | `/v1/biometric/login` | `{device_id, biometric_token}` | public token, no user token |

## `UserRepository`

| Method | Path | Body / Query | Notes |
|---|---|---|---|
| GET | `/users/info` | `?token=` | current profile |
| POST | `/users/change/password` | `{current_password, new_password}` | |
| POST | `/users/change/info` | full profile | |
| POST | `/users/change/profile` | partial (name/contact/social/company/VAT) | |
| POST | `/users/change/address` | main + shipping address | |
| POST | `/users/request_remove` | `{reason}` | account deletion request |
| POST | `/users/request_remove/confirm` | `{email, code}` | confirm via email link |

## `AddressRepository`

| Method | Path | Body / Query | Notes |
|---|---|---|---|
| GET | `/users/address` | — | list |
| POST | `/users/address/store` | full_name, phone, address, house_number, postal_code, location, country, is_default | create |
| POST | `/users/address/update/{id}` | same fields | update |
| POST | `/users/address/delete/{id}` | — | delete |

## `NotificationRepository`

| Method | Path | Body / Query | Notes |
|---|---|---|---|
| GET | `/users/notifications/{id}` | — | full detail, triggered from FCM data payload |
| GET | `/users/notifications` | `?time={cursor}` | cursor pagination |

FCM topics (no data channel usage beyond triggering the above): `public`, per-platform topic,
`user_{id_encode}`.

## `StreamRepository` (live streaming)

| Method | Path | Body / Query | Notes |
|---|---|---|---|
| GET | `/studios/extension/list/live` | `?type=&id_encode=` | live stream list |
| POST | `/studios/extension/stream/messages` | `{account, from_user, studio_id, log_id, comment, message_id, full_name, type, source_type}` | chat fallback for web/social (non in-app) streams |
| GET | `/studios/extension/stream/log` | `?id=&sort=desc` | poll every 5s — current selling product, only when stream is NOT in-app |
| POST | `/studios/stream/start` | `{productName, price, quantity, image, image_thumb}` | |
| POST | `/studios/stream/end` | `{id}` | |
| GET | `/studios/stream/last_stream` | — | poll for own in-progress stream |
| POST | `/studios/stream/load/messages` | `{id}` | |
| GET | `/schedules/noti` | `?id=` | scheduled livestream detail, from push notification |

## `StudioRepository`

| Method | Path | Body / Query | Notes |
|---|---|---|---|
| POST | `/studios/interactions` | `?id=&type=` | like/unlike or follow/unfollow |
| GET | `/studios/list/interaction` | `?type=&limit=&page=` | all / like / follow / top_rated |
| GET | `/studios/list/interaction/filters` | — | filter labels |

## `GameRepository` (Blackjack + Lucky Wheel)

| Method | Path | Body / Query | Notes |
|---|---|---|---|
| GET | `/mobile/blackjack/stats` | — | |
| POST | `/mobile/blackjack/record` | `{score, cards_count}` | |
| GET | `/games/spinwheel/list` | `?f=` | active lucky-wheel studios |
| GET | `/games/spinwheel/get/{studioIdEncode}` | — | wheel config |
| POST | `/games/spinwheel/save_result` | `{studio_id, spinwheel_id, results[]}` | |

## `StoreRepository` (catalog / cart / checkout)

| Method | Path | Body / Query | Notes |
|---|---|---|---|
| GET | `/stores/settings/filters` | `?id=` | |
| GET | `/stores/detail` | `?id=` | |
| GET | `/stores/categories` | `?id=` | |
| GET | `/stores/settings/homepage` | — | |
| GET | `/stores/studio/homepage-zones` | `?id=` | |
| GET | `/stores/product/popular` | `?limit=&q=&category=&price_min=&price_max=` | |
| GET | `/stores/product/best-selling` | same filters | |
| GET | `/stores/product/list` | `?page=&limit=&q=&id=&category=&price_min=&price_max=&min_rating=&sort=&random_seed=&is_mall=&brand_id=` | |
| GET | `/stores/product/{idEncode}` | — | product detail |
| GET | `/stores/product/{idEncode}/related` | `?limit=&page=` | |
| POST | `/stores/checkout/buy-now` | `{product_id, quantity, price_type}` | |
| POST | `/stores/cart/add` | `{product_id, quantity, price_type}` | |
| POST | `/stores/cart/list` | — | |
| POST | `/stores/cart/count` | — | |
| POST | `/stores/cart/update` | `{product_id, quantity}` | |
| POST | `/stores/cart/remove` | `{product_id}` | |
| POST | `/stores/cart/clear` | — | |
| POST | `/stores/checkout/update-address` | `?id=&address_id=` | |
| POST | `/stores/checkout/process` | FormData `{id, payment_method}` (default `bank_transfer`) | |
| POST | `/stores/checkout/create` | FormData `{items: "id1,id2,..."}` | |
| POST | `/stores/checkout/get` | FormData `{id, price_type}` | |
| GET | `/stores/checkout/success` | `?id=` | |
| GET | `/stores/brand/list` | — | |

## `OrderRepository`

| Method | Path | Body / Query | Notes |
|---|---|---|---|
| GET | `/shop/users/orders/menu` | — | order status filters |
| GET | `/shop/users/orders` | `?page=&status=&s=&create_from=` | |
| GET | `/shop/users/orders/detail` | `?id=` | |
| POST | `/shop/users/orders/update-address` | `?id=&address_id=` | |
| POST | `/vouchers/code/redeem` | `{code, order_id}` | |

## `PaymentRepository`

| Method | Path | Body / Query | Notes |
|---|---|---|---|
| POST | `/mobile/payments/create` | `?id=&source=mobile` | returns provider hand-off payload (Mollie checkout URL, opened in a WebView) |

## `ReviewRepository`

| Method | Path | Body / Query | Notes |
|---|---|---|---|
| GET | `/v1/reviews/list` | `?status=&page=` | status: not_reviewed / reviewed |
| GET | `/v1/reviews/product/{productId}` | `?filter=&page=` | |
| GET | `/v1/reviews/write/{idEncode}` | — | |
| POST | `/v1/reviews/submit` | — | |
| GET | `/v1/reviews/store-stats/{studioIdEncode}` | — | |
| GET | `/v1/reviews/store/{studioIdEncode}` | `?filter=&page=` | |
| POST | `/v1/reviews/bulk-check-status` | `{id_encodes[]}` | |

## `ChatRepository` (Ably-backed order/support chat — distinct from live-room chat)

| Method | Path | Body / Query | Notes |
|---|---|---|---|
| POST | `/chat/broadcasting/auth` | `{token}` | issues Ably token, TTL 1h, wildcard channel capability |
| GET | `/chat/conversations` | `?context=account\|studio&channel=&page=&per_page=` | |
| GET | `/chat/orders/{orderId}/messages` | `?limit=&before_ts=&before_id=&preview=` | |
| POST | `/chat/orders/{orderId}/messages` | form-urlencoded `{body, body_html?, request_id?}` | |
| GET | `/chat/support/messages` | `?limit=&before_ts=&preview=` | |
| POST | `/chat/support/messages` | form-urlencoded `{body, body_html?, request_id?}` | |
| POST | `/chat/conversations/{id}/active` | `{ttl}` | suppresses push while conversation is open |
| DELETE | `/chat/conversations/{id}/active` | — | |
| POST | `/chat/conversations/{id}/read` | — | |
| POST | `/chat/sync-unread` | — | |

Ably realtime channels (not REST): `private:conversation.{conversationId}` (event `message.sent`),
`private:App.Models.User.{userId}` (event `chat.notification`).

## `MediaRepository`

| Method | Path | Body / Query | Notes |
|---|---|---|---|
| POST | `/media/upload/file` | multipart: `file` (or `url`), `key`, `folder`, `storage`, `size`, `type`, `ratio`, `for_id` | images, video (chat), documents (chat files) |

## `StaticContentRepository`

| Method | Path | Body / Query | Notes |
|---|---|---|---|
| GET | `/static/app_slides` | `?token=` | |
| GET | `/static/statistic` | `?token=` | |
| GET | `/static/app_reviews` | `?token=` | |
| GET | `/studios/extension/list/categories` | — | |
| GET | *(arbitrary path)* | — | generic slide-fetcher, hits whatever path is passed |

## `LocationRepository`

| Method | Path | Body / Query | Notes |
|---|---|---|---|
| GET | `/location/list/country` | `?token=` | cacheable |

## `ForumRepository` (feature-flagged OFF in the source app — confirm scope before implementing)

| Method | Path | Body / Query | Notes |
|---|---|---|---|
| GET | `/v1/forum/menu-data` | — | |
| GET | `/v1/forum/{parentSlug}[/{childSlug}]` | `?page=` | |
| GET | `/v1/forum/me` / `/v1/forum/me/media` | `?page=&type=` | |
| GET | `/v1/forum/detail/{threadId}` | `?page=` | |
| POST | `/v1/forum/react/` | `{post_id, type}` | 1=like, 2=dislike |
| POST | `/v1/forum/comment` | — | |
| POST | `/v1/forum/thread/save[/{id}]` | — | create / update post |
| DELETE | `/v1/forum/delete/{postId}` | — | |
| GET | `/v1/forum/categories` | — | |

---

## Realtime layer — Firebase Realtime Database (NOT REST)

Viewer counts, in-app live chat, and the auction leaderboard have **no REST equivalent** — the
Flutter client reads/writes these paths directly. The iOS app needs the Firebase iOS SDK pointed at
the same database URL, not just a REST client, to reproduce this.

| RTDB path | Purpose | Direction |
|---|---|---|
| `studio_live_rooms/{studioId}` | Current room state (is_live, viewer_count) — new schema, dual-writes to legacy path below | read/write |
| `active_live_rooms/{userId}`, `live_rooms/{userId}` | Legacy per-streamer room state | read fallback |
| `live_rooms_by_studio/{studioId}` | Index: studio → streamer userId | read |
| `studio_messages/{studioId}/{YYYY-MM-DD}/{messageId}` | In-app live chat, date-partitioned — dual-writes to legacy path below | read/write |
| `live_messages/{streamerUserId}` | Legacy live chat | read fallback |
| `studio_live_log/{studioId}` | Current selling product/session for in-app streams (the RTDB equivalent of REST `stream/log`) | read/write |
| `studio_active_viewers/{studioId}/{YYYY-MM-DD}/{platformType}/{deviceId} = true` | Per-platform in-app viewer presence — count children, no stored total | read/write |
| `live_stream_top_bid/{streamIdEncode}` | Auction/bid leaderboard (`top_1`, `top_2`, ...) | **read-only** — written server-side |
| `live_reactions/{streamId}` | Heart/flower reactions, last 50, self-cleans after 1h | read/write |
| `live_errors/{YYYY-MM-DD}/{autoId}` | Best-effort client error telemetry sink | write only |

Selection rule for the "now selling" card: use `studio_live_log` (Firebase) when the stream is
in-app; use REST `/studios/extension/stream/log` polling (5s) when the stream is a web/social
(TikTok/Twitch/YouTube) session. Mirror this branch — do not always prefer one source.

**Firebase Auth**: anonymous sign-in only, required to satisfy RTDB security rules (`auth != null`).
Not tied to the app's own user/session system — do not gate app login on this.

**Firebase Remote Config**: source for (a) `api_domain_*` / `api_token_*` overrides layered on top of
the compile-time `Environment`, (b) forced app-update banners (`app_update_enabled_*`,
`app_update_min_version_name_*`, `app_update_store_url_*`), (c) feature flags (forum, marketplace).

**Firebase Cloud Messaging**: push notifications only, no data channel beyond triggering
`GET /users/notifications/{id}` and deep-link navigation.

---

## Summary — which protocol per feature

| Feature | Protocol |
|---|---|
| Auth/session, profile, address, orders, payment, cart/checkout, reviews, forum, static content, chat REST calls | REST |
| Order/support chat delivery | Ably (token from REST `/chat/broadcasting/auth`) |
| Live chat (in-app stream) | Firebase RTDB |
| Live viewer counts | Firebase RTDB |
| Auction/bid leaderboard | Firebase RTDB, read-only |
| "Now selling" product card | Firebase RTDB if in-app, else REST polling |
| Reactions (heart/flower) | Firebase RTDB |
| Push notifications | FCM topics + REST detail fetch |
| Feature flags / forced update | Firebase Remote Config |
