"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { type ColumnDef } from "@tanstack/react-table";
import { DataTable } from "@/components/data-table/data-table";
import { Badge } from "@/components/ui/badge";
import { Select } from "@/components/ui/select";
import { formatDateTime } from "@/lib/format";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Eye } from "lucide-react";
import { useState } from "react";

type AuditLogRow = {
  id: string;
  action: string;
  entity_type: string;
  entity_id: string;
  old_data: Record<string, unknown> | null;
  new_data: Record<string, unknown> | null;
  ip_address: string | null;
  created_at: string;
  actor: { full_name: string } | null;
};

function DataViewerButton({ data, label }: { data: Record<string, unknown> | null; label: string }) {
  const [open, setOpen] = useState(false);
  if (!data) return <span className="text-muted-foreground">-</span>;
  return (
    <>
      <Button variant="ghost" size="sm" onClick={() => setOpen(true)}>
        <Eye className="mr-1 h-3 w-3" />
        {label}
      </Button>
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{label}</DialogTitle>
          </DialogHeader>
          <pre className="max-h-[400px] overflow-auto rounded-lg bg-muted p-4 text-xs">
            {JSON.stringify(data, null, 2)}
          </pre>
        </DialogContent>
      </Dialog>
    </>
  );
}

const columns: ColumnDef<AuditLogRow, unknown>[] = [
  {
    accessorKey: "created_at",
    header: "Timestamp",
    cell: ({ row }) => (
      <span className="whitespace-nowrap text-sm">{formatDateTime(row.original.created_at)}</span>
    ),
  },
  {
    accessorKey: "actor.full_name",
    header: "Admin",
    cell: ({ row }) => row.original.actor?.full_name || "System",
  },
  {
    accessorKey: "action",
    header: "Action",
    cell: ({ row }) => (
      <Badge variant="outline">{row.original.action.replace(/_/g, " ")}</Badge>
    ),
  },
  {
    accessorKey: "entity_type",
    header: "Entity",
    cell: ({ row }) => (
      <div>
        <p className="text-sm">{row.original.entity_type}</p>
        <p className="font-mono text-xs text-muted-foreground">
          {row.original.entity_id.slice(0, 8)}...
        </p>
      </div>
    ),
  },
  {
    id: "old_data",
    header: "Before",
    cell: ({ row }) => <DataViewerButton data={row.original.old_data} label="Before" />,
  },
  {
    id: "new_data",
    header: "After",
    cell: ({ row }) => <DataViewerButton data={row.original.new_data} label="After" />,
  },
  {
    accessorKey: "ip_address",
    header: "IP",
    cell: ({ row }) => (
      <span className="font-mono text-xs">{row.original.ip_address || "-"}</span>
    ),
  },
];

interface AuditLogsTableProps {
  logs: AuditLogRow[];
  totalCount: number;
  page: number;
  pageSize: number;
  currentAction: string;
  currentEntityType: string;
}

export function AuditLogsTable({
  logs,
  totalCount,
  page,
  pageSize,
  currentAction,
  currentEntityType,
}: AuditLogsTableProps) {
  const router = useRouter();
  const searchParams = useSearchParams();

  const updateFilter = (key: string, value: string) => {
    const params = new URLSearchParams(searchParams.toString());
    if (value) {
      params.set(key, value);
    } else {
      params.delete(key);
    }
    params.set("page", "1");
    router.push(`/audit-logs?${params.toString()}`);
  };

  const handlePageChange = (newPage: number) => {
    const params = new URLSearchParams(searchParams.toString());
    params.set("page", newPage.toString());
    router.push(`/audit-logs?${params.toString()}`);
  };

  return (
    <DataTable
      columns={columns}
      data={logs}
      totalCount={totalCount}
      page={page}
      pageSize={pageSize}
      onPageChange={handlePageChange}
      filterComponent={
        <div className="flex gap-2">
          <Select value={currentEntityType} onValueChange={(v) => updateFilter("entity_type", v)}>
            <option value="">All Entities</option>
            <option value="profiles">Profiles</option>
            <option value="worker_profiles">Workers</option>
            <option value="reports">Reports</option>
            <option value="disputes">Disputes</option>
            <option value="payouts">Payouts</option>
            <option value="categories">Categories</option>
            <option value="skills">Skills</option>
            <option value="system_settings">Settings</option>
          </Select>
          <Select value={currentAction} onValueChange={(v) => updateFilter("action", v)}>
            <option value="">All Actions</option>
            <option value="ban_user">Ban User</option>
            <option value="unban_user">Unban User</option>
            <option value="suspend_user">Suspend User</option>
            <option value="add_strike">Add Strike</option>
            <option value="verify_worker">Verify Worker</option>
            <option value="reject_worker">Reject Worker</option>
            <option value="report_resolved">Resolve Report</option>
            <option value="report_dismissed">Dismiss Report</option>
            <option value="process_payout">Process Payout</option>
            <option value="update_setting">Update Setting</option>
          </Select>
        </div>
      }
    />
  );
}
