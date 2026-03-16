"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { type ColumnDef } from "@tanstack/react-table";
import { DataTable } from "@/components/data-table/data-table";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Select } from "@/components/ui/select";
import { Eye } from "lucide-react";
import { formatDate } from "@/lib/format";
import { statusColors } from "@/lib/constants";
import Link from "next/link";

type ReportRow = {
  id: string;
  reason: string;
  status: string;
  created_at: string;
  reporter: { full_name: string } | null;
  reported: { full_name: string } | null;
};

const columns: ColumnDef<ReportRow, unknown>[] = [
  {
    accessorKey: "reason",
    header: "Reason",
    cell: ({ row }) => (
      <p className="max-w-[200px] truncate font-medium">{row.original.reason}</p>
    ),
  },
  {
    accessorKey: "reporter.full_name",
    header: "Reporter",
    cell: ({ row }) => row.original.reporter?.full_name || "Unknown",
  },
  {
    accessorKey: "reported.full_name",
    header: "Reported User",
    cell: ({ row }) => row.original.reported?.full_name || "Unknown",
  },
  {
    accessorKey: "status",
    header: "Status",
    cell: ({ row }) => (
      <Badge className={statusColors[row.original.status] || ""}>
        {row.original.status}
      </Badge>
    ),
  },
  {
    accessorKey: "created_at",
    header: "Submitted",
    cell: ({ row }) => formatDate(row.original.created_at),
  },
  {
    id: "actions",
    cell: ({ row }) => (
      <Link href={`/reports/${row.original.id}`}>
        <Button variant="ghost" size="sm">
          <Eye className="mr-2 h-4 w-4" />
          Review
        </Button>
      </Link>
    ),
  },
];

interface ReportsTableProps {
  reports: ReportRow[];
  totalCount: number;
  page: number;
  pageSize: number;
  currentStatus: string;
}

export function ReportsTable({
  reports,
  totalCount,
  page,
  pageSize,
  currentStatus,
}: ReportsTableProps) {
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
    router.push(`/reports?${params.toString()}`);
  };

  const handlePageChange = (newPage: number) => {
    const params = new URLSearchParams(searchParams.toString());
    params.set("page", newPage.toString());
    router.push(`/reports?${params.toString()}`);
  };

  return (
    <DataTable
      columns={columns}
      data={reports}
      totalCount={totalCount}
      page={page}
      pageSize={pageSize}
      onPageChange={handlePageChange}
      filterComponent={
        <Select value={currentStatus} onValueChange={(v) => updateFilter("status", v)}>
          <option value="">All Statuses</option>
          <option value="pending">Pending</option>
          <option value="reviewing">Reviewing</option>
          <option value="resolved">Resolved</option>
          <option value="dismissed">Dismissed</option>
        </Select>
      }
    />
  );
}
