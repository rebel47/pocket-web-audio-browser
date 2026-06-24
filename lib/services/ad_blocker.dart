/// Lightweight domain-based ad and tracker blocker.
///
/// Works by matching every WebView resource request URL against a set of
/// known ad-serving and tracking domains.  Matching is host-based:
/// a request is blocked when its host equals a blocked domain or is a
/// subdomain of one (e.g. `ads.example.com` is blocked by `example.com`).
class AdBlocker {
  AdBlocker._();

  // ---------------------------------------------------------------------------
  // Blocked domains
  // ---------------------------------------------------------------------------

  static const Set<String> _blockedDomains = {
    // ── Google advertising & analytics ──────────────────────────────────────
    'doubleclick.net',
    'ad.doubleclick.net',
    'googlesyndication.com',
    'googleadservices.com',
    'googletagservices.com',
    'adservice.google.com',
    'imasdk.googleapis.com', // YouTube / Google IMA video-ad SDK
    'google-analytics.com',
    'analytics.google.com',
    'pagead2.googlesyndication.com',

    // ── Facebook / Meta ──────────────────────────────────────────────────────
    'connect.facebook.net',
    'an.facebook.com',
    'graph.facebook.com',     // only the ad/analytics calls come from here
    'staticxx.facebook.com',

    // ── Twitter / X ──────────────────────────────────────────────────────────
    'analytics.twitter.com',
    'static.ads-twitter.com',
    'ads-twitter.com',

    // ── Programmatic / DSP / SSP ─────────────────────────────────────────────
    'adnxs.com',              // AppNexus / Xandr
    'rubiconproject.com',
    'pubmatic.com',
    'openx.net',
    'openx.com',
    'spotxchange.com',
    'spotx.tv',
    'criteo.com',
    'criteo.net',
    'taboola.com',
    'outbrain.com',
    'outbrainimg.com',
    'mediamath.com',
    'turn.com',
    'rlcdn.com',
    'sitescout.com',
    'yieldmanager.com',
    'yldbt.com',
    'advertising.com',
    'adtech.de',
    'adform.net',
    'adform.com',
    'flashtalking.com',
    'smartadserver.com',
    'sovrn.com',
    'lijit.com',
    'indexexchange.com',
    'casalemedia.com',
    'sharethrough.com',
    'triplelift.com',
    '33across.com',
    'rhythmone.com',
    'lkqd.net',
    'lkqd.com',
    'undertone.com',
    'conversantmedia.com',
    'epsilon.com',
    'admanager.google.com',
    'aswpsdk.amazon.com',
    'amazon-adsystem.com',

    // ── Tracking / Data brokers ───────────────────────────────────────────────
    'demdex.net',             // Adobe Audience Manager
    'bluekai.com',
    'krxd.net',
    'quantserve.com',
    'quantcount.com',
    'scorecardresearch.com',
    'comscore.com',
    'moatads.com',
    'adsafeprotected.com',
    'doubleverify.com',
    'adsrvr.org',             // The Trade Desk
    'tns-counter.ru',
    'hotjar.com',
    'fullstory.com',
    'loggly.com',
    'newrelic.com',           // performance tracking (not ads, but often unwanted)
    'nr-data.net',

    // ── Amazon advertising ────────────────────────────────────────────────────
    'fls-na.amazon.com',
    'unagi.amazon.com',

    // ── Misc ad servers ───────────────────────────────────────────────────────
    'ads.yahoo.com',
    'gemini.yahoo.com',
    'adserver.yahoo.com',
    'bid.g.doubleclick.net',
    'tpc.googlesyndication.com',
    'ade.googlesyndication.com',
    'cm.g.doubleclick.net',
    'stats.g.doubleclick.net',
    'sync.mathtag.com',
    'pixel.mathtag.com',
    'ads.linkedin.com',
    'px.ads.linkedin.com',
    'snap.licdn.com',
  };

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns `true` when [url] should be blocked.
  static bool shouldBlock(String url) {
    try {
      final host = Uri.parse(url).host.toLowerCase();
      if (host.isEmpty) return false;

      for (final domain in _blockedDomains) {
        if (host == domain || host.endsWith('.$domain')) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
