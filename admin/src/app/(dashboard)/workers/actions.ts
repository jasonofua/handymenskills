"use server";

import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import { revalidatePath } from "next/cache";

async function getAdminId() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  return user?.id;
}

async function logAudit(
  adminId: string,
  action: string,
  entityType: string,
  entityId: string,
  oldData: Record<string, unknown> | null,
  newData: Record<string, unknown> | null
) {
  const admin = createAdminClient();
  await admin.from("audit_logs").insert({
    actor_id: adminId,
    action,
    entity_type: entityType,
    entity_id: entityId,
    old_data: oldData,
    new_data: newData,
  });
}

export async function verifyWorker(workerProfileId: string, notes: string) {
  const adminId = await getAdminId();
  if (!adminId) return { error: "Not authenticated" };

  const admin = createAdminClient();

  const { data: current } = await admin
    .from("worker_profiles")
    .select("verification_status, user_id")
    .eq("id", workerProfileId)
    .single();

  const { error } = await admin
    .from("worker_profiles")
    .update({
      verification_status: "verified",
      verification_notes: notes || null,
      verified_at: new Date().toISOString(),
      verified_by: adminId,
      is_available: true,
    })
    .eq("id", workerProfileId);

  if (error) return { error: error.message };

  // Send notification to worker
  if (current?.user_id) {
    await admin.from("notifications").insert({
      user_id: current.user_id,
      title: "Verification Approved",
      body: "Your worker profile has been verified. You can now accept jobs.",
      type: "verification_approved",
    });
  }

  await logAudit(adminId, "verify_worker", "worker_profiles", workerProfileId, { verification_status: current?.verification_status }, { verification_status: "verified", notes });
  revalidatePath("/workers");
  revalidatePath(`/workers/${workerProfileId}`);
  return { success: true };
}

export async function rejectWorker(workerProfileId: string, notes: string) {
  const adminId = await getAdminId();
  if (!adminId) return { error: "Not authenticated" };

  if (!notes) return { error: "Rejection notes are required" };

  const admin = createAdminClient();

  const { data: current } = await admin
    .from("worker_profiles")
    .select("verification_status, user_id")
    .eq("id", workerProfileId)
    .single();

  const { error } = await admin
    .from("worker_profiles")
    .update({
      verification_status: "rejected",
      verification_notes: notes,
      verified_at: new Date().toISOString(),
      verified_by: adminId,
    })
    .eq("id", workerProfileId);

  if (error) return { error: error.message };

  if (current?.user_id) {
    await admin.from("notifications").insert({
      user_id: current.user_id,
      title: "Verification Rejected",
      body: `Your verification was rejected. Reason: ${notes}`,
      type: "verification_rejected",
    });
  }

  await logAudit(adminId, "reject_worker", "worker_profiles", workerProfileId, { verification_status: current?.verification_status }, { verification_status: "rejected", notes });
  revalidatePath("/workers");
  revalidatePath(`/workers/${workerProfileId}`);
  return { success: true };
}
