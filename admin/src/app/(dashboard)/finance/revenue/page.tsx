import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/layout/page-header";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { MetricCard } from "@/components/charts/metric-card";
import { formatNaira } from "@/lib/format";
import { Wallet, TrendingUp, CreditCard, PiggyBank } from "lucide-react";
import { RevenueDetailChart } from "./revenue-detail-chart";

export default async function RevenuePage() {
  const supabase = await createClient();
  const now = new Date();

  // Compute monthly data for 12 months
  const monthlyData = [];
  let totalRevenue = 0;
  let totalPayouts = 0;
  let totalTransactions = 0;

  for (let i = 11; i >= 0; i--) {
    const monthStart = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const monthEnd = new Date(now.getFullYear(), now.getMonth() - i + 1, 0, 23, 59, 59);
    const monthLabel = monthStart.toLocaleDateString("en-US", { month: "short", year: "2-digit" });

    const { data: payments, count } = await supabase
      .from("payments")
      .select("amount", { count: "exact" })
      .eq("status", "success")
      .gte("created_at", monthStart.toISOString())
      .lte("created_at", monthEnd.toISOString());

    const gmv = payments?.reduce((sum, p) => sum + (p.amount || 0), 0) || 0;
    const revenue = gmv;
    const payouts = 0;

    totalRevenue += revenue;
    totalPayouts += payouts;
    totalTransactions += count || 0;

    monthlyData.push({
      month: monthLabel,
      revenue,
      payouts,
      gmv,
    });
  }

  const thisMonthRevenue = monthlyData[monthlyData.length - 1]?.revenue || 0;
  const lastMonthRevenue = monthlyData[monthlyData.length - 2]?.revenue || 0;
  const revenueGrowth = lastMonthRevenue > 0
    ? ((thisMonthRevenue - lastMonthRevenue) / lastMonthRevenue) * 100
    : 0;

  return (
    <div className="space-y-6">
      <PageHeader title="Revenue Analytics" description="Platform financial performance" />

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <MetricCard
          title="Total Revenue (12mo)"
          value={formatNaira(totalRevenue)}
          icon={Wallet}
        />
        <MetricCard
          title="This Month"
          value={formatNaira(thisMonthRevenue)}
          change={revenueGrowth}
          icon={TrendingUp}
          description="vs last month"
        />
        <MetricCard
          title="Total Payouts (12mo)"
          value={formatNaira(totalPayouts)}
          icon={CreditCard}
        />
        <MetricCard
          title="Total Transactions"
          value={totalTransactions.toLocaleString()}
          icon={PiggyBank}
        />
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Revenue vs Payouts (12 Months)</CardTitle>
        </CardHeader>
        <CardContent>
          <RevenueDetailChart data={monthlyData} />
        </CardContent>
      </Card>
    </div>
  );
}
