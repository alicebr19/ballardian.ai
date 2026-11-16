// Ballardian "unfurl": given the web address of a Substack essay, return its title,
// subtitle, author, cover image, date and length, so a writer can share it on the Essays
// tab without retyping. Signed-in members only. It reads Substack's public post data and
// nothing else: https only, no IP addresses or ports, and redirects are not followed blindly.

const ALLOWED_ORIGINS = ["https://ballardian.ai", "http://ballardian.ai", "https://www.ballardian.ai"];
const PUBLISHABLE_KEY = "sb_publishable_ZjB4zPlSTgOMF5GDyuOJEw_j5rhlGLf"; // public by design

export function parseEssayUrl(input: string): { origin: string; slug: string } {
  let u: URL;
  try { u = new URL(String(input).trim()); } catch { throw new Error("That is not a web address."); }
  if (u.protocol !== "https:" || u.username || u.password || u.port) throw new Error("Use the essay's https address.");
  let host = u.hostname.toLowerCase();
  let path = u.pathname;
  const open = host === "open.substack.com" && path.match(/^\/pub\/([a-z0-9-]+)(\/p\/.+)$/i);
  if (open) { host = open[1].toLowerCase() + ".substack.com"; path = open[2]; }
  const okHost = /^[a-z0-9-]+(\.[a-z0-9-]+)+$/.test(host) && !/^\d+(\.\d+){3}$/.test(host) &&
    !/(^|\.)(localhost|local|internal|lan|home|corp)$/.test(host);
  if (!okHost) throw new Error("That address cannot be used.");
  const m = path.match(/^\/p\/([A-Za-z0-9%_-]{1,200})\/?$/);
  if (!m) throw new Error("Use the essay's own address, the one with /p/ in it.");
  return { origin: "https://" + host, slug: m[1] };
}

export async function unfurl(input: string) {
  let { origin, slug } = parseEssayUrl(input);
  let res: Response | null = null;
  for (let hop = 0; hop < 2; hop++) {
    res = await fetch(origin + "/api/v1/posts/" + slug, {
      redirect: "manual", headers: { accept: "application/json" }, signal: AbortSignal.timeout(8000),
    });
    if (res.status < 300 || res.status >= 400) break;
    // A Substack on its own domain answers with one redirect to that domain; check it like the first address.
    const next = new URL(res.headers.get("location") || "", origin);
    const m = next.pathname.match(/^\/api\/v1\/posts\/([A-Za-z0-9%_-]{1,200})$/);
    if (!m) throw new Error("Substack did not return that essay.");
    ({ origin, slug } = parseEssayUrl(next.origin + "/p/" + m[1]));
  }
  if (!res || !res.ok) throw new Error("Substack did not return that essay. Check the address.");
  const text = await res.text();
  if (text.length > 4_000_000) throw new Error("That essay is too large to read.");
  let d: any;
  try { d = JSON.parse(text); } catch { throw new Error("That address is not a Substack essay."); }
  if (!d || typeof d.title !== "string" || !d.title.trim()) throw new Error("That address is not a Substack essay.");
  const cover = typeof d.cover_image === "string" && /^https:\/\/(substackcdn\.com|substack-post-media\.s3\.amazonaws\.com)\//.test(d.cover_image) && d.cover_image.length <= 1000 ? d.cover_image : null;
  const names = Array.isArray(d.publishedBylines) ? d.publishedBylines.map((b: any) => b && b.name).filter((n: unknown) => typeof n === "string" && n) : [];
  return {
    url: origin + "/p/" + slug,
    title: d.title.trim().slice(0, 200),
    subtitle: (typeof d.subtitle === "string" ? d.subtitle : typeof d.description === "string" ? d.description : "").trim().slice(0, 300),
    author: names.join(", ").slice(0, 120),
    cover,
    date: typeof d.post_date === "string" && !isNaN(Date.parse(d.post_date)) ? new Date(d.post_date).toISOString() : null,
    words: Number.isFinite(d.wordcount) && d.wordcount >= 0 && d.wordcount < 1_000_000 ? Math.round(d.wordcount) : null,
    paid: d.audience === "only_paid",
  };
}

// @ts-ignore: Deno is present on Supabase; the check lets the same file run in tests elsewhere.
if (typeof Deno !== "undefined") {
  // @ts-ignore
  Deno.serve(async (req: Request) => {
    const origin = req.headers.get("origin") || "";
    const headers: Record<string, string> = {
      "content-type": "application/json",
      "access-control-allow-origin": ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0],
      "access-control-allow-headers": "authorization, apikey, content-type, x-client-info",
      "access-control-allow-methods": "POST, OPTIONS",
      "vary": "origin",
    };
    const reply = (status: number, body: unknown) => new Response(JSON.stringify(body), { status, headers });
    if (req.method === "OPTIONS") return new Response("ok", { headers });
    if (req.method !== "POST") return reply(405, { error: "POST only." });
    try {
      // @ts-ignore
      const who = await fetch(Deno.env.get("SUPABASE_URL") + "/auth/v1/user", {
        headers: { apikey: PUBLISHABLE_KEY, authorization: req.headers.get("authorization") || "" },
      });
      if (!who.ok) return reply(401, { error: "Sign in first." });
      const body = await req.json().catch(() => ({}));
      return reply(200, await unfurl(String(body.url || "")));
    } catch (e) {
      return reply(400, { error: e instanceof Error ? e.message : "Could not read that address." });
    }
  });
}
