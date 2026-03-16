import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/layout/page-header";
import { DEFAULT_PAGE_SIZE } from "@/lib/constants";
import { Badge } from "@/components/ui/badge";
import { formatDate, formatNaira } from "@/lib/format";
import { statusColors } from "@/lib/constants";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Card, CardContent } from "@/components/ui/card";
import Link from "next/link";
import { Button } from "@/components/ui/button";

interface Props {
  searchParams: Promise<{ page?: string; status?: string }>;
}

export default async function SubscriptionsPage({ searchParams }: Props) {
  const params = await searchParams;
  const page = parseInt(params.page || "1", 10);
  const status = params.status || "";
  const offset = (page - 1) * DEFAULT_PAGE_SIZE;

  const supabase = await createClient();

  let query = supabase
    .from("subscriptions")
    .select(
      "*, profiles!subscriptions_worker_id_fkey(full_name, email), subscription_plans(name, price, duration_months)",
      { count: "exact" }
    )
    .order("created_at", { ascending: false })
    .range(offset, offset + DEFAULT_PAGE_SIZE - 1);

  if (status) query = query.eq("status", status);

  const { data: subscriptions, count } = await query;

  return (
    <div className="space-y-6">
      <PageHeader title="Subscriptions" description="Active subscriber list">
        <Link href="/subscriptions/plans">
          <Button variant="outline">Manage Plans</Button>
        </Link>
      </PageHeader>

      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>User</TableHead>
                <TableHead>Plan</TableHead>
                <TableHead>Price</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Current Period</TableHead>
                <TableHead>Created</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {!subscriptions || subscriptions.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} className="text-center text-muted-foreground">
                    No subscriptions found.
                  </TableCell>
                </TableRow>
              ) : (
                subscriptions.map((sub) => {
                  const profile = sub.profiles as { full_name: string; email: string | null } | null;
                  const plan = sub.subscription_plans as { name: string; price: number; duration_months: number } | null;
                  return (
                    <TableRow key={sub.id}>
                      <TableCell>
                        <div>
                          <p className="font-medium">{profile?.full_name || "Unknown"}</p>
                          <p className="text-xs text-muted-foreground">{profile?.email || ""}</p>
                        </div>
                      </TableCell>
                      <TableCell>{plan?.name || "N/A"}</TableCell>
                      <TableCell>
                        {plan ? `${formatNaira(plan.price)}/${plan.duration_months}mo` : "N/A"}
                      </TableCell>
                      <TableCell>
                        <Badge className={statusColors[sub.status] || ""}>
                          {sub.status}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-sm">
                        {formatDate(sub.starts_at)} - {formatDate(sub.expires_at)}
                      </TableCell>
                      <TableCell>{formatDate(sub.created_at)}</TableCell>
                    </TableRow>
                  );
                })
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <div className="flex items-center justify-between text-sm text-muted-foreground">
        <p>Total: {count || 0} subscriptions</p>
        <div className="flex gap-2">
          {page > 1 && (
            <Link href={`/subscriptions?page=${page - 1}${status ? `&status=${status}` : ""}`}>
              <Button variant="outline" size="sm">Previous</Button>
            </Link>
          )}
          {(count || 0) > page * DEFAULT_PAGE_SIZE && (
            <Link href={`/subscriptions?page=${page + 1}${status ? `&status=${status}` : ""}`}>
              <Button variant="outline" size="sm">Next</Button>
            </Link>
          )}
        </div>
      </div>
    </div>
  );
}
