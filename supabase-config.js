
// ==========================================
// PIXORA - SUPABASE CONFIGURATION
// ==========================================

window.PIXORA_SUPABASE_URL =
    "https://uoctgvpflfzbvrahdwtv.supabase.co";

window.PIXORA_SUPABASE_ANON_KEY =
    "sb_publishable_59ymVeiSYW4NviWulqpczA_fOEQQw56";

// ==========================================
// INITIALIZE SUPABASE
// ==========================================

if (!window.supabase) {
    console.error("[PIXORA] Supabase SDK belum dimuat!");
} else {
    try {
        window.PIXORA_SUPABASE = window.supabase.createClient(
            window.PIXORA_SUPABASE_URL,
            window.PIXORA_SUPABASE_ANON_KEY,
            {
                auth: {
                    persistSession: true,
                    autoRefreshToken: true,
                    detectSessionInUrl: true
                }
            }
        );

        console.log("[PIXORA] Supabase connected successfully!");
    } catch (error) {
        console.error("[PIXORA] Supabase initialization failed:", error);
    }
}
