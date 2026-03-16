"use server";

import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import { revalidatePath } from "next/cache";

export async function resolveDispute(
  disputeId: string,
  resolution: "resolved_client_favor" | "resolved_worker_favor" | "resolved_mutual",
  notes: string,
  refundAmount: number | null
) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "Not authenticated" };

  if (!notes.trim()) return { error: "Resolution notes are required" };

  const admin = createAdminClient();

  const { data: current } = await admin
    .from("disputes")
    .select("status, booking_id")
    .eq("id", disputeId)
    .single();

  if (!current) return { error: "Dispute not found" };
  if (!["open", "under_review"].includes(current.status)) {
    return { error: "Dispute is already resolved" };
  }

  const { error } = await admin
    .from("disputes")
    .update({
      status: resolution,
      resolution_notes: notes,
      resolved_by: user.id,
      resolved_at: new Date().toISOString(),
      refund_amount: refundAmount,
    })
    .eq("id", disputeId);

  if (error) return { error: error.message };

  // Update booking status to reflect resolution
  if (current.booking_id) {
    await admin
      .from("bookings")
      .update({ status: "completed" })
      .eq("id", current.booking_id);
  }

  await admin.from("audit_logs").insert({
    actor_id: user.id,
    action: `dispute_${resolution}`,
    entity_type: "disputes",
    entity_id: disputeId,
    old_data: { status: current.status },
    new_data: { status: resolution, notes, refund_amount: refundAmount },
  });

  revalidatePath("/disputes");
  revalidatePath(`/disputes/${disputeId}`);
  return { success: true };
}
