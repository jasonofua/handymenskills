import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/layout/page-header";
import { DEFAULT_PAGE_SIZE } from "@/lib/constants";
import { WorkersTable } from "./workers-table";

interface Props {
  searchParams: Promise<{ page?: string; status?: string }>;
}

export default async function WorkersPage({ searchParams }: Props) {
  const params = await searchParams;
  const page = parseInt(params.page || "1", 10);
  const status = params.status || "pending";
  const offset = (page - 1) * DEFAULT_PAGE_SIZE;

  const supabase = await createClient();

  let query = supabase
    .from("worker_profiles")
    .select("*, profiles(id, full_name, email, phone, avatar_url, city, state)", { count: "exact" })
    .order("created_at", { ascending: false })
    .range(offset, offset + DEFAULT_PAGE_SIZE - 1);

  if (status) query = query.eq("verification_status", status);

  const { data: workers, count } = await query;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Worker Verification"
        description="Review and verify worker profiles"
      />
      <WorkersTable
        workers={workers || []}
        totalCount={count || 0}
        page={page}
        pageSize={DEFAULT_PAGE_SIZE}
        currentStatus={status}
      />
    </div>
  );
}
