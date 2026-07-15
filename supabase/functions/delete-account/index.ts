import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

serve(async (request) => {
  if (request.method !== "POST") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), {
      status: 405,
      headers: { "content-type": "application/json" },
    });
  }

  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return new Response(JSON.stringify({ error: "unauthorized" }), {
      status: 401,
      headers: { "content-type": "application/json" },
    });
  }

  const supabaseURL = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseURL || !anonKey || !serviceRoleKey) {
    return new Response(JSON.stringify({ error: "server_not_configured" }), {
      status: 500,
      headers: { "content-type": "application/json" },
    });
  }

  const userClient = createClient(supabaseURL, anonKey, {
    global: { headers: { Authorization: authorization } },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return new Response(JSON.stringify({ error: "unauthorized" }), {
      status: 401,
      headers: { "content-type": "application/json" },
    });
  }

  const adminClient = createClient(supabaseURL, serviceRoleKey);
  const { error } = await adminClient.auth.admin.deleteUser(userData.user.id);
  if (error) {
    return new Response(JSON.stringify({ error: "delete_failed" }), {
      status: 500,
      headers: { "content-type": "application/json" },
    });
  }

  return new Response(null, { status: 204 });
});
