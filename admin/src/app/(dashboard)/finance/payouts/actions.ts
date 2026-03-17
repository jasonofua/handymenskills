"use server";

import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import { revalidatePath } from "next/cache";

export async function processPayout(payoutId: string) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "Not authenticated" };

  const admin = createAdminClient();

  const { data: payout } = await admin
    .from("payouts")
    .select("status")
    .eq("id", payoutId)
    .single();

  if (!payout) return { error: "Payout not found" };
  if (payout.status !== "pending") return { error: "Payout is not in pending status" };

  const { error } = await admin
    .from("payouts")
    .update({
      status: "completed",
      processed_at: new Date().toISOString(),
    })
    .eq("id", payoutId);

  if (error) return { error: error.message };

  await admin.from("audit_logs").insert({
    actor_id: user.id,
    action: "process_payout",
    entity_type: "payouts",
    entity_id: payoutId,
    old_data: { status: "pending" },
    new_data: { status: "completed" },
  });

  revalidatePath("/finance/payouts");
  return { success: true };
}
