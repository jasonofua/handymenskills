import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import { DashboardShell } from "./dashboard-shell";

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", user.id)
    .single();

  if (!profile || profile.role !== "admin") {
    redirect("/login");
  }

  const { count: pendingVerifications } = await supabase
    .from("worker_profiles")
    .select("*", { count: "exact", head: true })
    .eq("verification_status", "pending");

  const { count: pendingReports } = await supabase
    .from("reports")
    .select("*", { count: "exact", head: true })
    .eq("status", "pending");

  const { count: openDisputes } = await supabase
    .from("disputes")
    .select("*", { count: "exact", head: true })
    .in("status", ["open", "under_review"]);

  const pendingCounts: Record<string, number> = {};
  if (pendingVerifications) pendingCounts["/workers"] = pendingVerifications;
  if (pendingReports) pendingCounts["/reports"] = pendingReports;
  if (openDisputes) pendingCounts["/disputes"] = openDisputes;

  return (
    <DashboardShell profile={profile} pendingCounts={pendingCounts}>
      {children}
    </DashboardShell>
  );
}
