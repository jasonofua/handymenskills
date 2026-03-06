import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/layout/page-header";
import { DEFAULT_PAGE_SIZE } from "@/lib/constants";
import { UsersTable } from "./users-table";

interface Props {
  searchParams: Promise<{ page?: string; status?: string; role?: string }>;
}

export default async function UsersPage({ searchParams }: Props) {
  const params = await searchParams;
  const page = parseInt(params.page || "1", 10);
  const status = params.status || "";
  const role = params.role || "";
  const offset = (page - 1) * DEFAULT_PAGE_SIZE;

  const supabase = await createClient();

  let query = supabase
    .from("profiles")
    .select("*", { count: "exact" })
    .order("created_at", { ascending: false })
    .range(offset, offset + DEFAULT_PAGE_SIZE - 1);

  if (status) query = query.eq("account_status", status);
  if (role) query = query.eq("role", role);

  const { data: users, count } = await query;

  return (
    <div className="space-y-6">
      <PageHeader title="Users" description="Manage all platform users" />
      <UsersTable
        users={users || []}
        totalCount={count || 0}
        page={page}
        pageSize={DEFAULT_PAGE_SIZE}
        currentStatus={status}
        currentRole={role}
      />
    </div>
  );
}
