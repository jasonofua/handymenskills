import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/layout/page-header";
import { DEFAULT_PAGE_SIZE } from "@/lib/constants";
import { PaymentsTable } from "./payments-table";

interface Props {
  searchParams: Promise<{ page?: string; status?: string }>;
}

export default async function FinancePage({ searchParams }: Props) {
  const params = await searchParams;
  const page = parseInt(params.page || "1", 10);
  const status = params.status || "";
  const offset = (page - 1) * DEFAULT_PAGE_SIZE;

  const supabase = await createClient();

  let query = supabase
    .from("payments")
    .select(
      "*, bookings(id, jobs(title)), payer:profiles!payments_user_id_fkey(full_name)",
      { count: "exact" }
    )
    .order("created_at", { ascending: false })
    .range(offset, offset + DEFAULT_PAGE_SIZE - 1);

  if (status) query = query.eq("status", status);

  const { data: payments, count } = await query;

  return (
    <div className="space-y-6">
      <PageHeader title="Payments" description="All payment transactions" />
      <PaymentsTable
        payments={payments || []}
        totalCount={count || 0}
        page={page}
        pageSize={DEFAULT_PAGE_SIZE}
        currentStatus={status}
      />
    </div>
  );
}
