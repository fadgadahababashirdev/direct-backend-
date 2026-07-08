# Direct — Frontend Integration Guide

This document provides everything the frontend developer needs to wire the backend to the frontend.

---

## 1. Tech Stack (Backend)
- **Platform:** Supabase (PostgreSQL + Auth + Edge Functions)
- **Realtime:** Supabase Realtime
- **Storage:** Supabase Storage
- **Email:** Resend (via custom SMTP)
- **Geo-discovery:** PostGIS
- **Payments:** Urubuto (MTN Mobile Money, Airtel Money)

---

## 2. Installation

Install the Supabase JS SDK:

```bash
npm install @supabase/supabase-js
```

---

## 3. Environment Variables

Create a `.env.local` file in the root of the frontend project:

```env
NEXT_PUBLIC_SUPABASE_URL=https://bmhwdocyicmocwtafnms.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
```

Get the anon key from:
**Supabase Dashboard → Project Settings → API → anon public key**

---

## 4. Supabase Client Setup

Create a file `lib/supabase.js`:

```javascript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
```

---

## 5. Auth

### Sign Up
```javascript
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'password123',
  options: {
    data: {
      username: 'johndoe',
      age: 24,
      gender: 'male' // 'male' | 'female' | 'others'
    }
  }
})
```

### Login
```javascript
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'password123'
})
```

### Logout
```javascript
await supabase.auth.signOut()
```

### Get Current Session
```javascript
const { data: { session } } = await supabase.auth.getSession()
```

### Listen to Auth State Changes
```javascript
supabase.auth.onAuthStateChange((event, session) => {
  if (event === 'SIGNED_IN') { /* handle signed in */ }
  if (event === 'SIGNED_OUT') { /* handle signed out */ }
  if (event === 'PASSWORD_RECOVERY') { /* handle recovery */ }
})
```

### Forgot Password
```javascript
await supabase.auth.resetPasswordForEmail('user@example.com', {
  redirectTo: 'https://yourapp.com/reset-password'
})
```

### Reset Password
```javascript
await supabase.auth.updateUser({
  password: 'new_password'
})
```

---

## 6. Profiles

### Get Current User Profile
```javascript
const { data, error } = await supabase
  .from('profiles')
  .select('*')
  .eq('id', session.user.id)
  .single()
```

### Update Profile
```javascript
const { data, error } = await supabase
  .from('profiles')
  .update({
    username: 'new_username',
    age: 26,
    avatar_url: 'https://...'
  })
  .eq('id', session.user.id)
```

---

## 7. User Preferences

### Save Preferences
```javascript
const { data, error } = await supabase
  .from('user_preferences')
  .upsert({
    user_id: session.user.id,
    gender_interest: 'female', // 'male' | 'female' | 'others'
    location_type: 'current', // 'current' | 'preferred'
    coords: `POINT(${longitude} ${latitude})`,
    search_radius_km: 3.0 // 1.0 | 2.0 | 3.0
  })
```

### Get Preferences
```javascript
const { data, error } = await supabase
  .from('user_preferences')
  .select('*')
  .eq('user_id', session.user.id)
  .single()
```

---

## 8. Discovery — Nearby Matches

```javascript
const { data, error } = await supabase.rpc('get_nearby_matches', {
  target_user_id: session.user.id,
  user_coords: `POINT(${longitude} ${latitude})`,
  radius_km: 3.0
})

// Returns:
// [
//   {
//     profile_id: 'uuid',
//     username: 'jane',
//     age: 23,
//     gender: 'female',
//     avatar_url: 'https://...',
//     distance_km: 1.32
//   }
// ]
```

---

## 9. Messaging

### Create a Chat
```javascript
const { data: chat } = await supabase
  .from('chats')
  .insert({})
  .select()
  .single()

// Add both users as members
await supabase.from('chat_members').insert([
  { chat_id: chat.id, user_id: session.user.id },
  { chat_id: chat.id, user_id: other_user_id }
])
```

### Send a Message
```javascript
await supabase.from('messages').insert({
  chat_id: chat_id,
  sender_id: session.user.id,
  content_encrypted: 'encrypted_message_here'
})
```

### Get Messages
```javascript
const { data, error } = await supabase
  .from('messages')
  .select('*')
  .eq('chat_id', chat_id)
  .order('created_at', { ascending: true })
```

### Realtime Messages
```javascript
supabase
  .channel('messages')
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'messages',
    filter: `chat_id=eq.${chat_id}`
  }, (payload) => {
    console.log('New message:', payload.new)
  })
  .subscribe()
```

---

## 10. Payments

### Initiate Payment
```javascript
const { data, error } = await supabase.functions.invoke('process-payment', {
  body: {
    user_id: session.user.id,
    plan: 'premium', // 'premium' | 'premium_plus' | 'verified_trust'
    payment_method: 'mtn', // 'mtn' | 'airtel' | 'card'
    phone_number: '+250780000000'
  }
})

// Returns:
// {
//   success: true,
//   transaction_id: 'TXN-xxx',
//   plan: 'premium',
//   amount: 2500,
//   currency: 'RWF',
//   expires_at: '2026-08-07T...'
// }
```

### Get User Subscription
```javascript
const { data, error } = await supabase
  .from('subscriptions')
  .select('*')
  .eq('user_id', session.user.id)
  .eq('status', 'active')
  .single()
```

---

## 11. Pricing

| Plan | Price | Duration |
|------|-------|----------|
| Free | 0 RWF | Forever |
| Premium | 2,500 RWF | Monthly |
| Premium Plus | 5,000 RWF | Monthly |
| Verified Trust | 10,000 RWF | One-time |

---

## 12. User Verification Flow

1. User signs up → confirmation email sent automatically
2. User clicks confirmation link → `is_verified` flips to `true`
3. If user doesn't verify within **15 days** → account locked
4. Frontend should check `is_verified` on every session and show persistent reminder if `false`

```javascript
// Check verification status
const { data: profile } = await supabase
  .from('profiles')
  .select('is_verified, created_at')
  .eq('id', session.user.id)
  .single()

if (!profile.is_verified) {
  // Show verification reminder banner
  // Calculate days remaining
  const createdAt = new Date(profile.created_at)
  const expiryDate = new Date(createdAt.getTime() + 15 * 24 * 60 * 60 * 1000)
  const daysRemaining = Math.ceil((expiryDate - new Date()) / (1000 * 60 * 60 * 24))
  // Show: "Please verify your email. X days remaining."
}
```

---

## 13. Auth Callback Page

Create a page at `/auth/callback` to handle email confirmation redirects:

```javascript
// pages/auth/callback.js or app/auth/callback/page.js
import { useEffect } from 'react'
import { supabase } from '@/lib/supabase'
import { useRouter } from 'next/router'

export default function AuthCallback() {
  const router = useRouter()

  useEffect(() => {
    supabase.auth.onAuthStateChange((event, session) => {
      if (event === 'SIGNED_IN') {
        router.push('/dashboard')
      }
    })
  }, [])

  return <div>Verifying your email...</div>
}
```

---

## 14. Database Schema Reference

### profiles
| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key, matches auth.users |
| username | text | Unique username |
| email | text | User email |
| age | integer | Must be 18+ |
| gender | text | male / female / others |
| role | text | user / admin |
| avatar_url | text | Profile picture URL |
| is_verified | boolean | Email verified status |
| created_at | timestamptz | Registration date |

### user_preferences
| Column | Type | Description |
|--------|------|-------------|
| user_id | uuid | References profiles |
| gender_interest | text | male / female / others |
| location_type | text | current / preferred |
| coords | geography | PostGIS point |
| search_radius_km | float | 1.0 / 2.0 / 3.0 |

### subscriptions
| Column | Type | Description |
|--------|------|-------------|
| user_id | uuid | References profiles |
| plan | text | free / premium / premium_plus / verified_trust |
| status | text | active / expired / cancelled |
| amount | integer | Amount in RWF |
| payment_method | text | mtn / airtel / card |
| transaction_id | text | Unique transaction reference |
| expires_at | timestamptz | Null for one-time plans |

---

## 15. GitHub Repository
https://github.com/fadgadahababashirdev/direct-backend-

---

## 16. Contact

For any backend questions reach out to the backend team.