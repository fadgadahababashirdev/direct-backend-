import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const PLAN_AMOUNTS: Record<string, number> = {
  premium: 2500,
  premium_plus: 5000,
  verified_trust: 10000,
};

serve(async (req) => {
  try {
    const { user_id, plan, payment_method, phone_number } = await req.json();

    // Validate plan
    if (!PLAN_AMOUNTS[plan]) {
      return new Response(
        JSON.stringify({ error: "Invalid plan selected" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Validate payment method
    if (!["mtn", "airtel", "card"].includes(payment_method)) {
      return new Response(
        JSON.stringify({ error: "Invalid payment method" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const amount = PLAN_AMOUNTS[plan];

    // Simulate payment processing
    // In production: integrate MTN Mobile Money or Airtel Money API here
    const transaction_id = `TXN-${Date.now()}-${Math.random().toString(36).substr(2, 9).toUpperCase()}`;
    const payment_successful = true; // Replace with real API call result

    if (!payment_successful) {
      return new Response(
        JSON.stringify({ error: "Payment failed. Please try again." }),
        { status: 402, headers: { "Content-Type": "application/json" } }
      );
    }

    // Calculate expiry date (verified_trust is one-time, others are monthly)
    const expires_at = plan === "verified_trust"
      ? null
      : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();

    // Save subscription to database
    const { data, error } = await supabase
      .from("subscriptions")
      .insert({
        user_id,
        plan,
        status: "active",
        amount,
        currency: "RWF",
        payment_method,
        transaction_id,
        starts_at: new Date().toISOString(),
        expires_at,
      })
      .select()
      .single();

    if (error) {
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // If verified_trust plan, update profile is_verified
    if (plan === "verified_trust") {
      await supabase
        .from("profiles")
        .update({ is_verified: true })
        .eq("id", user_id);
    }

    return new Response(
      JSON.stringify({
        success: true,
        transaction_id,
        plan,
        amount,
        currency: "RWF",
        expires_at,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});