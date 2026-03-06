"use server";

import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import { revalidatePath } from "next/cache";

export async function updateSetting(key: string, value: string) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "Not authenticated" };

  const admin = createAdminClient();

  const { data: current } = await admin
    .from("system_settings")
    .select("value")
    .eq("key", key)
    .single();

  const { error } = await admin
    .from("system_settings")
    .update({
      value,
      updated_by: user.id,
      updated_at: new Date().toISOString(),
    })
    .eq("key", key);

  if (error) return { error: error.message };

  await admin.from("audit_logs").insert({
    actor_id: user.id,
    action: "update_setting",
    entity_type: "system_settings",
    entity_id: key,
    old_data: { value: current?.value },
    new_data: { value },
  });

  revalidatePath("/settings");
  return { success: true };
}

export async function createSetting(key: string, value: string, description: string) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "Not authenticated" };

  const admin = createAdminClient();

  const { error } = await admin.from("system_settings").insert({
    key,
    value,
    description: description || null,
    updated_by: user.id,
  });

  if (error) return { error: error.message };

  await admin.from("audit_logs").insert({
    actor_id: user.id,
    action: "create_setting",
    entity_type: "system_settings",
    entity_id: key,
    old_data: null,
    new_data: { key, value, description },
  });

  revalidatePath("/settings");
  return { success: true };
}
