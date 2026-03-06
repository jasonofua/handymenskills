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

export async function banUser(userId: string) {
  const adminId = await getAdminId();
  if (!adminId) return { error: "Not authenticated" };

  const admin = createAdminClient();
  const { data: current } = await admin
    .from("profiles")
    .select("account_status")
    .eq("id", userId)
    .single();

  const { error } = await admin
    .from("profiles")
    .update({ account_status: "banned" })
    .eq("id", userId);

  if (error) return { error: error.message };

  await logAudit(adminId, "ban_user", "profiles", userId, { account_status: current?.account_status }, { account_status: "banned" });
  revalidatePath("/users");
  revalidatePath(`/users/${userId}`);
  return { success: true };
}

export async function unbanUser(userId: string) {
  const adminId = await getAdminId();
  if (!adminId) return { error: "Not authenticated" };

  const admin = createAdminClient();
  const { data: current } = await admin
    .from("profiles")
    .select("account_status")
    .eq("id", userId)
    .single();

  const { error } = await admin
    .from("profiles")
    .update({ account_status: "active" })
    .eq("id", userId);

  if (error) return { error: error.message };

  await logAudit(adminId, "unban_user", "profiles", userId, { account_status: current?.account_status }, { account_status: "active" });
  revalidatePath("/users");
  revalidatePath(`/users/${userId}`);
  return { success: true };
}

export async function suspendUser(userId: string) {
  const adminId = await getAdminId();
  if (!adminId) return { error: "Not authenticated" };

  const admin = createAdminClient();
  const { data: current } = await admin
    .from("profiles")
    .select("account_status")
    .eq("id", userId)
    .single();

  const { error } = await admin
    .from("profiles")
    .update({ account_status: "suspended" })
    .eq("id", userId);

  if (error) return { error: error.message };

  await logAudit(adminId, "suspend_user", "profiles", userId, { account_status: current?.account_status }, { account_status: "suspended" });
  revalidatePath("/users");
  revalidatePath(`/users/${userId}`);
  return { success: true };
}

export async function addStrike(userId: string) {
  const adminId = await getAdminId();
  if (!adminId) return { error: "Not authenticated" };

  const admin = createAdminClient();
  const { data: current } = await admin
    .from("profiles")
    .select("strikes")
    .eq("id", userId)
    .single();

  const newStrikes = (current?.strikes || 0) + 1;

  const updateData: { strikes: number; account_status?: string } = { strikes: newStrikes };
  if (newStrikes >= 3) {
    updateData.account_status = "banned";
  }

  const { error } = await admin
    .from("profiles")
    .update(updateData)
    .eq("id", userId);

  if (error) return { error: error.message };

  await logAudit(adminId, "add_strike", "profiles", userId, { strikes: current?.strikes }, { strikes: newStrikes, ...(newStrikes >= 3 ? { account_status: "banned" } : {}) });
  revalidatePath("/users");
  revalidatePath(`/users/${userId}`);
  return { success: true, strikes: newStrikes };
}
