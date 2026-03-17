import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/layout/page-header";
import { DEFAULT_PAGE_SIZE } from "@/lib/constants";
import { PayoutsTable } from "./payouts-table";

interface Props {
  searchParams: Promise<{ page?: string; status?: string }>;
}

export default async function PayoutsPage({ searchParams }: Props) {
  const params = await searchParams;
  const page = parseInt(params.page || "1", 10);
  const status = params.status || "";
  const offset = (page - 1) * DEFAULT_PAGE_SIZE;

  const supabase = await createClient();

  let query = supabase
    .from("payouts")
    .select(
      "*, worker:profiles!payouts_worker_id_fkey(full_name)",
      { count: "exact" }
    )
    .order("created_at", { ascending: false })
    .range(offset, offset + DEFAULT_PAGE_SIZE - 1);

  if (status) query = query.eq("status", status);

  const { data: payouts, count } = await query;

  return (
    <div className="space-y-6">
      <PageHeader title="Payouts" description="Worker payout management" />
      <PayoutsTable
        payouts={payouts || []}
        totalCount={count || 0}
        page={page}
        pageSize={DEFAULT_PAGE_SIZE}
        currentStatus={status}
      />
    </div>
  );
}
