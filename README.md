# Denz iPhones

Official online storefront for **Denz iPhones** in Soweto, South Africa.

## Live Website

https://denziphone.com/

## Store

Browse:
- Sealed Box iPhones (XR through 15 Pro Max)
- Brand New iPhones (16 through 18)
- Pre-Owned iPhones
- Cheaper Options
- Current price information
- Lay-by information
- Direct WhatsApp ordering

Website created by [Spirit2k5 Web Studio](https://spirit2k5.co.za/).

## Storefront maintenance

After editing `assets/js/categories.js` or a file in `assets/js/parts`, run:

```sh
node scripts/build-store.cjs
```

This creates the single `assets/js/store.js` bundle. The storefront waits for inventory before rendering, without synchronous requests or dynamic evaluation.

Every dedicated iPhone page uses its explicit product ID for its gallery, configuration, cart actions and customer reviews. Reviews are stored in Supabase, appear publicly only after approval, and receive verified-purchase status from paid-order records. The SQL files in `supabase/migrations` record the review access changes already applied to the hosted project; they supplement its existing schema.
