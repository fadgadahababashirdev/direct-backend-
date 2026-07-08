import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  try {
    const { recipient_id, sender_id, message } = await req.json();

    // Initialize Supabase client
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Fetch recipient's profile
    const { data: recipient, error: recipientError } = await supabase
      .from("profiles")
      .select("username, email")
      .eq("id", recipient_id)
      .single();

    if (recipientError || !recipient) {
      return new Response(
        JSON.stringify({ error: "Recipient not found" }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    // Fetch sender's profile
    const { data: sender, error: senderError } = await supabase
      .from("profiles")
      .select("username")
      .eq("id", sender_id)
      .single();

    if (senderError || !sender) {
      return new Response(
        JSON.stringify({ error: "Sender not found" }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    // Log the notification (push service can be plugged in here)
    console.log(`Notification to ${recipient.username}: ${message} from ${sender.username}`);

    return new Response(
      JSON.stringify({
        success: true,
        notification: {
          recipient: recipient.username,
          sender: sender.username,
          message,
        },
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