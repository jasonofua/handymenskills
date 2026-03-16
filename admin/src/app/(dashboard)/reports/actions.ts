"use server";

import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import { revalidatePath } from "next/cache";

export async function resolveReport(
  reportId: string,
  resolution: "resolved" | "dismissed",
  notes: string
) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "Not authenticated" };

  if (!notes.trim()) return { error: "Resolution notes are required" };

  const admin = createAdminClient();

  const { data: current } = await admin
    .from("reports")
    .select("status, reported_id")
    .eq("id", reportId)
    .single();

  if (!current) return { error: "Report not found" };

  const { error } = await admin
    .from("reports")
    .update({
      status: resolution,
      resolution_notes: notes,
      resolved_by: user.id,
      resolved_at: new Date().toISOString(),
    })
    .eq("id", reportId);

  if (error) return { error: error.message };

  // If resolved (not dismissed), add a strike to the reported user
  if (resolution === "resolved" && current.reported_id) {
    const { data: profile } = await admin
      .from("profiles")
      .select("strikes")
      .eq("id", current.reported_id)
      .single();

    if (profile) {
      const newStrikes = (profile.strikes || 0) + 1;
      const update: { strikes: number; account_status?: string } = { strikes: newStrikes };
      if (newStrikes >= 3) {
        update.account_status = "banned";
      }
      await admin.from("profiles").update(update).eq("id", current.reported_id);
    }
  }

  await admin.from("audit_logs").insert({
    actor_id: user.id,
    action: `report_${resolution}`,
    entity_type: "reports",
    entity_id: reportId,
    old_data: { status: current.status },
    new_data: { status: resolution, notes },
  });

  revalidatePath("/reports");
  revalidatePath(`/reports/${reportId}`);
  return { success: true };
}
