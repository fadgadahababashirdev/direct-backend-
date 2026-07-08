const { createClient } = require("@supabase/supabase-js");

const supabase = createClient(
  "https://bmhwdocyicmocwtafnms.supabase.co",
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJtaHdkb2N5aWNtb2N3dGFmbm1zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM0OTM5NTEsImV4cCI6MjA5OTA2OTk1MX0.Ict4lpj0rT7QFjO3XWpmFxs-MbZvOwQvc3Fg8rUYg8o"
);

async function testPayment() {
  const { data, error } = await supabase.functions.invoke("process-payment", {
    body: {
      user_id: "e1e2e3e4-0000-0000-0000-000000000001",
      plan: "premium",
      payment_method: "mtn",
      phone_number: "+250780000000",
    },
  });

  if (error) {
    console.error("Payment error:", JSON.stringify(error, null, 2));
  } else {
    console.log("Payment success!", JSON.stringify(data, null, 2));
  }
}

testPayment();