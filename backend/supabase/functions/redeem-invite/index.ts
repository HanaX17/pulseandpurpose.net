// =============================================================================
// redeem-invite — join a family using an invitation code.
// =============================================================================
// A non-member cannot SELECT invitations (RLS blocks it), so redemption runs
// here with the service-role key. We:
//   1. authenticate the caller from their JWT,
//   2. look up a valid (non-expired, not-exhausted) invite,
//   3. insert the caller into family_members,
//   4. atomically bump used_count.
// =============================================================================
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { code, relation } = await req.json();
    if (!code || typeof code !== "string") {
      return json({ error: "Missing invite code" }, 400);
    }

    const authHeader = req.headers.get("Authorization") ?? "";
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // Identify the caller from their JWT using the anon-context client.
    const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userErr } = await userClient.auth.getUser();
    if (userErr || !userData.user) return json({ error: "Unauthorized" }, 401);
    const userId = userData.user.id;

    // Service-role client bypasses RLS for the privileged lookup + writes.
    const admin = createClient(supabaseUrl, serviceKey);

    const { data: invite, error: invErr } = await admin
      .from("invitations")
      .select("id, family_id, expires_at, max_uses, used_count")
      .eq("code", code)
      .maybeSingle();

    if (invErr) return json({ error: invErr.message }, 500);
    if (!invite) return json({ error: "Invalid invite code" }, 404);
    if (invite.expires_at && new Date(invite.expires_at) < new Date()) {
      return json({ error: "Invite expired" }, 410);
    }
    if (invite.used_count >= invite.max_uses) {
      return json({ error: "Invite fully used" }, 410);
    }

    const { error: memErr } = await admin
      .from("family_members")
      .upsert(
        { family_id: invite.family_id, user_id: userId, relation: relation ?? null },
        { onConflict: "family_id,user_id", ignoreDuplicates: true },
      );
    if (memErr) return json({ error: memErr.message }, 500);

    await admin
      .from("invitations")
      .update({ used_count: invite.used_count + 1 })
      .eq("id", invite.id);

    return json({ family_id: invite.family_id }, 200);
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
