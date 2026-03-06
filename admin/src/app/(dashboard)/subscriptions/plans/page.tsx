import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/layout/page-header";
import { PlansManager } from "./plans-manager";

export default async function PlansPage() {
  const supabase = await createClient();

  const { data: plans } = await supabase
    .from("subscription_plans")
    .select("*")
    .order("price", { ascending: true });

  return (
    <div className="space-y-6">
      <PageHeader
        title="Subscription Plans"
        description="Manage subscription plan offerings"
      />
      <PlansManager initialPlans={plans || []} />
    </div>
  );
}
