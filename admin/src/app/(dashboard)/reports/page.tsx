import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/layout/page-header";
import { DEFAULT_PAGE_SIZE } from "@/lib/constants";
import { ReportsTable } from "./reports-table";

interface Props {
  searchParams: Promise<{ page?: string; status?: string }>;
}

export default async function ReportsPage({ searchParams }: Props) {
  const params = await searchParams;
  const page = parseInt(params.page || "1", 10);
  const status = params.status || "pending";
  const offset = (page - 1) * DEFAULT_PAGE_SIZE;

  const supabase = await createClient();

  let query = supabase
    .from("reports")
    .select(
      "*, reporter:profiles!reports_reporter_id_fkey(full_name), reported:profiles!reports_reported_id_fkey(full_name)",
      { count: "exact" }
    )
    .order("created_at", { ascending: false })
    .range(offset, offset + DEFAULT_PAGE_SIZE - 1);

  if (status) query = query.eq("report_status", status);

  const { data: reports, count } = await query;

  return (
    <div className="space-y-6">
      <PageHeader title="Reports" description="User reports and complaints" />
      <ReportsTable
        reports={reports || []}
        totalCount={count || 0}
        page={page}
        pageSize={DEFAULT_PAGE_SIZE}
        currentStatus={status}
      />
    </div>
  );
}
