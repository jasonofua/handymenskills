import { createClient } from "@/lib/supabase/server";
import { MetricCard } from "@/components/charts/metric-card";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { PageHeader } from "@/components/layout/page-header";
import { formatNaira, formatRelative } from "@/lib/format";
import { Users, Briefcase, HardHat, Wallet, ShieldCheck, Flag, Scale } from "lucide-react";
import Link from "next/link";
import { RevenueChart } from "./revenue-chart";

async function getDashboardData() {
  const supabase = await createClient();

  const now = new Date();
  const thisMonth = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();
  const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1).toISOString();
  const lastMonthEnd = new Date(now.getFullYear(), now.getMonth(), 0).toISOString();

  const [
    { count: totalUsers },
    { count: totalUsersLastMonth },
    { count: activeWorkers },
    { count: activeWorkersLastMonth },
    { count: totalJobs },
    { count: totalJobsLastMonth },
    { data: revenueBookings },
    { data: revenueLastMonthBookings },
    { count: pendingVerifications },
    { count: pendingReports },
    { count: openDisputes },
    { data: recentBookings },
  ] = await Promise.all([
    supabase.from("profiles").select("*", { count: "exact", head: true }),
    supabase.from("profiles").select("*", { count: "exact", head: true }).lt("created_at", thisMonth),
    supabase.from("worker_profiles").select("*", { count: "exact", head: true }).eq("verification_status", "verified"),
    supabase.from("worker_profiles").select("*", { count: "exact", head: true }).eq("verification_status", "verified").lt("created_at", thisMonth),
    supabase.from("jobs").select("*", { count: "exact", head: true }),
    supabase.from("jobs").select("*", { count: "exact", head: true }).lt("created_at", thisMonth),
    supabase.from("bookings").select("platform_commission").in("status", ["completed", "client_confirmed"]).gte("created_at", thisMonth),
    supabase.from("bookings").select("platform_commission").in("status", ["completed", "client_confirmed"]).gte("created_at", lastMonth).lt("created_at", thisMonth),
    supabase.from("worker_profiles").select("*", { count: "exact", head: true }).eq("verification_status", "pending"),
    supabase.from("reports").select("*", { count: "exact", head: true }).eq("status", "pending"),
    supabase.from("disputes").select("*", { count: "exact", head: true }).in("status", ["open", "under_review"]),
    supabase.from("bookings").select("id, status, agreed_price, created_at, client:profiles!bookings_client_id_fkey(full_name), worker:profiles!bookings_worker_id_fkey(full_name)").order("created_at", { ascending: false }).limit(5),
  ]);

  const totalRevenue = revenueBookings?.reduce((sum, b) => sum + (b.platform_commission || 0), 0) || 0;
  const lastMonthRevenue = revenueLastMonthBookings?.reduce((sum, b) => sum + (b.platform_commission || 0), 0) || 0;

  const calcGrowth = (current: number, previous: number) =>
    previous === 0 ? (current > 0 ? 100 : 0) : ((current - previous) / previous) * 100;

  const userGrowth = calcGrowth(totalUsers || 0, totalUsersLastMonth || 0);
  const workerGrowth = calcGrowth(activeWorkers || 0, activeWorkersLastMonth || 0);
  const jobGrowth = calcGrowth(totalJobs || 0, totalJobsLastMonth || 0);
  const revenueGrowth = calcGrowth(totalRevenue, lastMonthRevenue);

  // Fetch last 6 months revenue for chart
  const chartData = [];
  for (let i = 5; i >= 0; i--) {
    const monthStart = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const monthEnd = new Date(now.getFullYear(), now.getMonth() - i + 1, 0, 23, 59, 59);
    const monthLabel = monthStart.toLocaleDateString("en-US", { month: "short", year: "2-digit" });

    const { data: monthBookings } = await supabase
      .from("bookings")
      .select("platform_commission, worker_payout")
      .in("status", ["completed", "client_confirmed"])
      .gte("created_at", monthStart.toISOString())
      .lte("created_at", monthEnd.toISOString());

    const revenue = monthBookings?.reduce((sum, b) => sum + (b.platform_commission || 0), 0) || 0;
    const payouts = monthBookings?.reduce((sum, b) => sum + (b.worker_payout || 0), 0) || 0;

    chartData.push({
      month: monthLabel,
      revenue,
      payouts,
      profit: revenue,
    });
  }

  return {
    stats: {
      totalUsers: totalUsers || 0,
      activeWorkers: activeWorkers || 0,
      totalJobs: totalJobs || 0,
      totalRevenue,
      userGrowth,
      workerGrowth,
      jobGrowth,
      revenueGrowth,
    },
    pending: {
      verifications: pendingVerifications || 0,
      reports: pendingReports || 0,
      disputes: openDisputes || 0,
    },
    chartData,
    recentBookings: recentBookings || [],
  };
}

export default async function DashboardPage() {
  const { stats, pending, chartData, recentBookings } = await getDashboardData();

  return (
    <div className="space-y-6">
      <PageHeader title="Dashboard" description="Overview of the Handymenskills platform" />

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <MetricCard
          title="Total Users"
          value={stats.totalUsers.toLocaleString()}
          change={stats.userGrowth}
          icon={Users}
          description="from last month"
        />
        <MetricCard
          title="Verified Workers"
          value={stats.activeWorkers.toLocaleString()}
          change={stats.workerGrowth}
          icon={HardHat}
          description="from last month"
        />
        <MetricCard
          title="Total Jobs"
          value={stats.totalJobs.toLocaleString()}
          change={stats.jobGrowth}
          icon={Briefcase}
          description="from last month"
        />
        <MetricCard
          title="Platform Revenue"
          value={formatNaira(stats.totalRevenue)}
          change={stats.revenueGrowth}
          icon={Wallet}
          description="this month"
        />
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="text-lg">Revenue Overview</CardTitle>
            <CardDescription>Platform revenue over the last 6 months</CardDescription>
          </CardHeader>
          <CardContent>
            <RevenueChart data={chartData} />
          </CardContent>
        </Card>

        <div className="space-y-4">
          <Link href="/workers">
            <Card className="cursor-pointer transition-colors hover:bg-muted/50">
              <CardContent className="flex items-center gap-4 p-6">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-amber-100">
                  <ShieldCheck className="h-5 w-5 text-amber-700" />
                </div>
                <div className="flex-1">
                  <p className="text-sm font-medium text-muted-foreground">Pending Verifications</p>
                  <p className="text-2xl font-bold">{pending.verifications}</p>
                </div>
              </CardContent>
            </Card>
          </Link>

          <Link href="/reports">
            <Card className="cursor-pointer transition-colors hover:bg-muted/50">
              <CardContent className="flex items-center gap-4 p-6">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-red-100">
                  <Flag className="h-5 w-5 text-red-700" />
                </div>
                <div className="flex-1">
                  <p className="text-sm font-medium text-muted-foreground">Open Reports</p>
                  <p className="text-2xl font-bold">{pending.reports}</p>
                </div>
              </CardContent>
            </Card>
          </Link>

          <Link href="/disputes">
            <Card className="cursor-pointer transition-colors hover:bg-muted/50">
              <CardContent className="flex items-center gap-4 p-6">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-orange-100">
                  <Scale className="h-5 w-5 text-orange-700" />
                </div>
                <div className="flex-1">
                  <p className="text-sm font-medium text-muted-foreground">Open Disputes</p>
                  <p className="text-2xl font-bold">{pending.disputes}</p>
                </div>
              </CardContent>
            </Card>
          </Link>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Recent Bookings</CardTitle>
          <CardDescription>Latest bookings across the platform</CardDescription>
        </CardHeader>
        <CardContent>
          {recentBookings.length === 0 ? (
            <p className="text-sm text-muted-foreground">No recent bookings.</p>
          ) : (
            <div className="space-y-4">
              {recentBookings.map((booking: Record<string, unknown>) => {
                const client = booking.client as { full_name: string } | null;
                const worker = booking.worker as { full_name: string } | null;
                return (
                  <div key={booking.id as string} className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div>
                        <p className="text-sm font-medium">
                          {client?.full_name || "Unknown"} &rarr; {worker?.full_name || "Unknown"}
                        </p>
                        <p className="text-xs text-muted-foreground">
                          {formatRelative(booking.created_at as string)}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-3">
                      <span className="text-sm font-medium">{formatNaira(booking.agreed_price as number)}</span>
                      <Badge
                        className={
                          (booking.status as string) === "completed"
                            ? "bg-emerald-100 text-emerald-800"
                            : (booking.status as string) === "cancelled"
                            ? "bg-red-100 text-red-800"
                            : "bg-blue-100 text-blue-800"
                        }
                      >
                        {(booking.status as string).replace(/_/g, " ")}
                      </Badge>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
