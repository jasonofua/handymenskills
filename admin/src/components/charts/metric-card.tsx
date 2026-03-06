import { Card, CardContent } from "@/components/ui/card";
import { cn } from "@/lib/utils";
import { type LucideIcon, TrendingUp, TrendingDown } from "lucide-react";

interface MetricCardProps {
  title: string;
  value: string;
  change?: number;
  icon: LucideIcon;
  description?: string;
}

export function MetricCard({ title, value, change, icon: Icon, description }: MetricCardProps) {
  const isPositive = change !== undefined && change >= 0;

  return (
    <Card>
      <CardContent className="p-6">
        <div className="flex items-center justify-between">
          <p className="text-sm font-medium text-muted-foreground">{title}</p>
          <Icon className="h-4 w-4 text-muted-foreground" />
        </div>
        <div className="mt-2">
          <p className="text-2xl font-bold">{value}</p>
          <div className="mt-1 flex items-center gap-1">
            {change !== undefined && (
              <>
                {isPositive ? (
                  <TrendingUp className="h-3.5 w-3.5 text-emerald-600" />
                ) : (
                  <TrendingDown className="h-3.5 w-3.5 text-red-600" />
                )}
                <span
                  className={cn(
                    "text-xs font-medium",
                    isPositive ? "text-emerald-600" : "text-red-600"
                  )}
                >
                  {isPositive ? "+" : ""}
                  {change.toFixed(1)}%
                </span>
              </>
            )}
            {description && (
              <span className="text-xs text-muted-foreground">{description}</span>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
