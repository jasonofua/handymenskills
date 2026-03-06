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
    .select("payout_status")
    .eq("id", payoutId)
    .single();

  if (!payout) return { error: "Payout not found" };
  if (payout.payout_status !== "pending") return { error: "Payout is not in pending status" };

  const { error } = await admin
    .from("payouts")
    .update({
      payout_status: "completed",
      processed_at: new Date().toISOString(),
      processed_by: user.id,
    })
    .eq("id", payoutId);

  if (error) return { error: error.message };

  await admin.from("audit_logs").insert({
    actor_id: user.id,
    action: "process_payout",
    entity_type: "payouts",
    entity_id: payoutId,
    old_data: { payout_status: "pending" },
    new_data: { payout_status: "completed" },
  });

  revalidatePath("/finance/payouts");
  return { success: true };
}
