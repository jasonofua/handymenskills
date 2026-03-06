import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/layout/page-header";
import { SettingsManager } from "./settings-manager";

export default async function SettingsPage() {
  const supabase = await createClient();

  const { data: settings } = await supabase
    .from("system_settings")
    .select("*")
    .order("key");

  const { data: admins } = await supabase
    .from("profiles")
    .select("id, full_name, email, created_at")
    .eq("role", "admin")
    .order("created_at");

  return (
    <div className="space-y-6">
      <PageHeader title="Settings" description="System configuration and admin management" />
      <SettingsManager
        initialSettings={settings || []}
        admins={admins || []}
      />
    </div>
  );
}
