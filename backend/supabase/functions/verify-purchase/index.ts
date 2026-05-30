// =============================================================================
// verify-purchase — STUB for App Store / Play Store receipt verification.
// =============================================================================
// The client sends a store receipt; we verify it with Apple/Google and then
// upsert the user's subscription row (service role). The real verification
// calls are left as TODOs — wiring them requires the app's store credentials.
// =============================================================================
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { store, receipt, productId } = await req.json();
    if (store !== "apple" && store !== "google") {
      return json({ error: "Unsupported store" }, 400);
    }
    if (!receipt) return json({ error: "Missing receipt" }, 400);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
    });
    const { data: userData, error: userErr } = await userClient.auth.getUser();
    if (userErr || !userData.user) return json({ error: "Unauthorized" }, 401);

    // ---------------------------------------------------------------------
    // TODO: verify `receipt` with the store.
    //   apple  -> POST https://buy.itunes.apple.com/verifyReceipt (App Store
    //             Server API / verifyReceipt), check bundle id + expiry.
    //   google -> Google Play Developer API
    //             purchases.subscriptions.get(packageName, subId, token).
    // For now we trust the client (DEV ONLY) and grant 30 days of premium.
    // ---------------------------------------------------------------------
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();

    const admin = createClient(supabaseUrl, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const { error: upErr } = await admin.from("subscriptions").upsert({
      user_id: userData.user.id,
      tier: "premium",
      status: "active",
      store,
      product_id: productId ?? null,
      expires_at: expiresAt,
      updated_at: new Date().toISOString(),
    });
    if (upErr) return json({ error: upErr.message }, 500);

    return json({ tier: "premium", expires_at: expiresAt }, 200);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
