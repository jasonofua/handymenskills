import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/layout/page-header";
import { DEFAULT_PAGE_SIZE } from "@/lib/constants";
import { JobsTable } from "./jobs-table";

interface Props {
  searchParams: Promise<{ page?: string; status?: string; urgency?: string; category?: string }>;
}

export default async function JobsPage({ searchParams }: Props) {
  const params = await searchParams;
  const page = parseInt(params.page || "1", 10);
  const status = params.status || "";
  const urgency = params.urgency || "";
  const offset = (page - 1) * DEFAULT_PAGE_SIZE;

  const supabase = await createClient();

  let query = supabase
    .from("jobs")
    .select("*, profiles!jobs_client_id_fkey(full_name, avatar_url), categories(name)", { count: "exact" })
    .order("created_at", { ascending: false })
    .range(offset, offset + DEFAULT_PAGE_SIZE - 1);

  if (status) query = query.eq("status", status);
  if (urgency) query = query.eq("urgency", urgency);

  const { data: jobs, count } = await query;

  const { data: categories } = await supabase
    .from("categories")
    .select("id, name")
    .eq("is_active", true)
    .order("name");

  return (
    <div className="space-y-6">
      <PageHeader title="Jobs" description="All jobs posted on the platform" />
      <JobsTable
        jobs={jobs || []}
        totalCount={count || 0}
        page={page}
        pageSize={DEFAULT_PAGE_SIZE}
        currentStatus={status}
        currentUrgency={urgency}
        categories={categories || []}
      />
    </div>
  );
}
