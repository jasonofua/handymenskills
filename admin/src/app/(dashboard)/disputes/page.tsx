import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/layout/page-header";
import { DEFAULT_PAGE_SIZE } from "@/lib/constants";
import { DisputesTable } from "./disputes-table";

interface Props {
  searchParams: Promise<{ page?: string; status?: string }>;
}

export default async function DisputesPage({ searchParams }: Props) {
  const params = await searchParams;
  const page = parseInt(params.page || "1", 10);
  const status = params.status || "";
  const offset = (page - 1) * DEFAULT_PAGE_SIZE;

  const supabase = await createClient();

  let query = supabase
    .from("disputes")
    .select(
      "*, raiser:profiles!disputes_raised_by_fkey(full_name), bookings(id, agreed_price, jobs(title))",
      { count: "exact" }
    )
    .order("created_at", { ascending: false })
    .range(offset, offset + DEFAULT_PAGE_SIZE - 1);

  if (status) {
    query = query.eq("dispute_status", status);
  } else {
    query = query.in("dispute_status", ["open", "under_review"]);
  }

  const { data: disputes, count } = await query;

  return (
    <div className="space-y-6">
      <PageHeader title="Disputes" description="Booking dispute resolution" />
      <DisputesTable
        disputes={disputes || []}
        totalCount={count || 0}
        page={page}
        pageSize={DEFAULT_PAGE_SIZE}
        currentStatus={status}
      />
    </div>
  );
}
