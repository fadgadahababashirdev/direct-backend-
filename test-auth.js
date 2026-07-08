const { createClient } = require("@supabase/supabase-js");

const supabase = createClient(
  "https://bmhwdocyicmocwtafnms.supabase.co",
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJtaHdkb2N5aWNtb2N3dGFmbm1zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM0OTM5NTEsImV4cCI6MjA5OTA2OTk1MX0.Ict4lpj0rT7QFjO3XWpmFxs-MbZvOwQvc3Fg8rUYg8o"
);

async function testSignUp() {
  const { data, error } = await supabase.auth.signUp({
    email: "onboarding@resend.dev",
    password: "Test@1234",
    options: {
      data: {
        username: "testuser",
        age: 24,
        gender: "male",
      },
    },
  });

  if (error) {
    console.error("Signup error:", JSON.stringify(error, null, 2));
    console.error("Status:", error.status);
    console.error("Message:", error.message);
    console.error("Details:", error.details);
    } else {
        console.log("Signup success!", JSON.stringify(data, null, 2));
    }
}

testSignUp();