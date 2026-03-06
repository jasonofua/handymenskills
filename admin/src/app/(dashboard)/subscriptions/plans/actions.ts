"use server";

import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import { revalidatePath } from "next/cache";

export async function createPlan(data: {
  name: string;
  description: string;
  price: number;
  interval: string;
}) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "Not authenticated" };

  const admin = createAdminClient();
  const slug = data.name.toLowerCase().replace(/\s+/g, "-").replace(/[^a-z0-9-]/g, "");

  const { error } = await admin.from("subscription_plans").insert({
    name: data.name,
    slug,
    description: data.description || null,
    price: data.price,
    interval: data.interval,
    is_active: true,
  });

  if (error) return { error: error.message };

  await admin.from("audit_logs").insert({
    actor_id: user.id,
    action: "create_plan",
    entity_type: "subscription_plans",
    entity_id: slug,
    old_data: null,
    new_data: data,
  });

  revalidatePath("/subscriptions/plans");
  return { success: true };
}

export async function updatePlan(
  id: string,
  data: { name: string; description: string; price: number; interval: string; is_active: boolean }
) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "Not authenticated" };

  const admin = createAdminClient();

  const { error } = await admin
    .from("subscription_plans")
    .update({
      name: data.name,
      description: data.description || null,
      price: data.price,
      interval: data.interval,
      is_active: data.is_active,
    })
    .eq("id", id);

  if (error) return { error: error.message };

  await admin.from("audit_logs").insert({
    actor_id: user.id,
    action: "update_plan",
    entity_type: "subscription_plans",
    entity_id: id,
    old_data: null,
    new_data: data,
  });

  revalidatePath("/subscriptions/plans");
  return { success: true };
}
