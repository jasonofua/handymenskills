"use server";

import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";
import { revalidatePath } from "next/cache";

async function getAdminId() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  return user?.id;
}

export async function createCategory(data: {
  name: string;
  slug: string;
  description: string;
  icon: string;
}) {
  const adminId = await getAdminId();
  if (!adminId) return { error: "Not authenticated" };

  const admin = createAdminClient();
  const { data: category, error } = await admin
    .from("categories")
    .insert({
      name: data.name,
      slug: data.slug,
      description: data.description || null,
      icon: data.icon || null,
      is_active: true,
      sort_order: 0,
    })
    .select()
    .single();

  if (error) return { error: error.message };

  await admin.from("audit_logs").insert({
    actor_id: adminId,
    action: "create_category",
    entity_type: "categories",
    entity_id: category.id,
    old_data: null,
    new_data: data,
  });

  revalidatePath("/categories");
  return { success: true, data: category };
}

export async function updateCategory(
  id: string,
  data: { name: string; slug: string; description: string; icon: string; is_active: boolean }
) {
  const adminId = await getAdminId();
  if (!adminId) return { error: "Not authenticated" };

  const admin = createAdminClient();
  const { error } = await admin
    .from("categories")
    .update({
      name: data.name,
      slug: data.slug,
      description: data.description || null,
      icon: data.icon || null,
      is_active: data.is_active,
    })
    .eq("id", id);

  if (error) return { error: error.message };

  await admin.from("audit_logs").insert({
    actor_id: adminId,
    action: "update_category",
    entity_type: "categories",
    entity_id: id,
    old_data: null,
    new_data: data,
  });

  revalidatePath("/categories");
  return { success: true };
}

export async function deleteCategory(id: string) {
  const adminId = await getAdminId();
  if (!adminId) return { error: "Not authenticated" };

  const admin = createAdminClient();
  const { error } = await admin.from("categories").delete().eq("id", id);

  if (error) return { error: error.message };

  await admin.from("audit_logs").insert({
    actor_id: adminId,
    action: "delete_category",
    entity_type: "categories",
    entity_id: id,
    old_data: null,
    new_data: null,
  });

  revalidatePath("/categories");
  return { success: true };
}

export async function createSkill(data: { name: string; category_id: string }) {
  const adminId = await getAdminId();
  if (!adminId) return { error: "Not authenticated" };

  const admin = createAdminClient();
  const { data: skill, error } = await admin
    .from("skills")
    .insert({
      name: data.name,
      category_id: data.category_id,
      is_active: true,
    })
    .select()
    .single();

  if (error) return { error: error.message };

  await admin.from("audit_logs").insert({
    actor_id: adminId,
    action: "create_skill",
    entity_type: "skills",
    entity_id: skill.id,
    old_data: null,
    new_data: data,
  });

  revalidatePath("/categories");
  return { success: true, data: skill };
}

export async function updateSkill(id: string, data: { name: string; category_id: string; is_active: boolean }) {
  const adminId = await getAdminId();
  if (!adminId) return { error: "Not authenticated" };

  const admin = createAdminClient();
  const { error } = await admin.from("skills").update(data).eq("id", id);

  if (error) return { error: error.message };

  await admin.from("audit_logs").insert({
    actor_id: adminId,
    action: "update_skill",
    entity_type: "skills",
    entity_id: id,
    old_data: null,
    new_data: data,
  });

  revalidatePath("/categories");
  return { success: true };
}

export async function deleteSkill(id: string) {
  const adminId = await getAdminId();
  if (!adminId) return { error: "Not authenticated" };

  const admin = createAdminClient();
  const { error } = await admin.from("skills").delete().eq("id", id);

  if (error) return { error: error.message };

  await admin.from("audit_logs").insert({
    actor_id: adminId,
    action: "delete_skill",
    entity_type: "skills",
    entity_id: id,
    old_data: null,
    new_data: null,
  });

  revalidatePath("/categories");
  return { success: true };
}
