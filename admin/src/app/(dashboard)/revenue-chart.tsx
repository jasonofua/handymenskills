"use client";

import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts";
import type { RevenueDataPoint } from "@/types";
import { formatNaira } from "@/lib/format";

export function RevenueChart({ data }: { data: RevenueDataPoint[] }) {
  if (data.length === 0) {
    return (
      <div className="flex h-[300px] items-center justify-center text-sm text-muted-foreground">
        No revenue data available
      </div>
    );
  }

  return (
    <ResponsiveContainer width="100%" height={300}>
      <AreaChart data={data} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
        <defs>
          <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor="hsl(var(--chart-1))" stopOpacity={0.3} />
            <stop offset="95%" stopColor="hsl(var(--chart-1))" stopOpacity={0} />
          </linearGradient>
          <linearGradient id="colorPayouts" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor="hsl(var(--chart-2))" stopOpacity={0.3} />
            <stop offset="95%" stopColor="hsl(var(--chart-2))" stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
        <XAxis dataKey="month" className="text-xs" tick={{ fill: "hsl(var(--muted-foreground))" }} />
        <YAxis
          className="text-xs"
          tick={{ fill: "hsl(var(--muted-foreground))" }}
          tickFormatter={(value) => formatNaira(value)}
        />
        <Tooltip
          formatter={(value, name) => [formatNaira(Number(value)), String(name) === "revenue" ? "Revenue" : "Payouts"]}
          contentStyle={{
            backgroundColor: "hsl(var(--background))",
            border: "1px solid hsl(var(--border))",
            borderRadius: "8px",
          }}
        />
        <Area
          type="monotone"
          dataKey="revenue"
          stroke="hsl(var(--chart-1))"
          fillOpacity={1}
          fill="url(#colorRevenue)"
          strokeWidth={2}
        />
        <Area
          type="monotone"
          dataKey="payouts"
          stroke="hsl(var(--chart-2))"
          fillOpacity={1}
          fill="url(#colorPayouts)"
          strokeWidth={2}
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}
