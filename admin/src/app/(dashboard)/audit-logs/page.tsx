import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/layout/page-header";
import { DEFAULT_PAGE_SIZE } from "@/lib/constants";
import { AuditLogsTable } from "./audit-logs-table";

interface Props {
  searchParams: Promise<{ page?: string; action?: string; entity_type?: string }>;
}

export default async function AuditLogsPage({ searchParams }: Props) {
  const params = await searchParams;
  const page = parseInt(params.page || "1", 10);
  const action = params.action || "";
  const entityType = params.entity_type || "";
  const offset = (page - 1) * DEFAULT_PAGE_SIZE;

  const supabase = await createClient();

  let query = supabase
    .from("audit_logs")
    .select("*, actor:profiles!audit_logs_actor_id_fkey(full_name)", { count: "exact" })
    .order("created_at", { ascending: false })
    .range(offset, offset + DEFAULT_PAGE_SIZE - 1);

  if (action) query = query.eq("action", action);
  if (entityType) query = query.eq("entity_type", entityType);

  const { data: logs, count } = await query;

  return (
    <div className="space-y-6">
      <PageHeader title="Audit Logs" description="Track all administrative actions" />
      <AuditLogsTable
        logs={logs || []}
        totalCount={count || 0}
        page={page}
        pageSize={DEFAULT_PAGE_SIZE}
        currentAction={action}
        currentEntityType={entityType}
      />
    </div>
  );
}
