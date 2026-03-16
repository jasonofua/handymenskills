"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { type ColumnDef } from "@tanstack/react-table";
import { DataTable } from "@/components/data-table/data-table";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Select } from "@/components/ui/select";
import { Eye } from "lucide-react";
import { formatDate, formatNaira } from "@/lib/format";
import { statusColors } from "@/lib/constants";
import Link from "next/link";

type DisputeRow = {
  id: string;
  reason: string;
  status: string;
  created_at: string;
  raiser: { full_name: string } | null;
  bookings: { id: string; agreed_price: number; jobs: { title: string } | null } | null;
};

const columns: ColumnDef<DisputeRow, unknown>[] = [
  {
    accessorKey: "reason",
    header: "Reason",
    cell: ({ row }) => (
      <p className="max-w-[200px] truncate font-medium">{row.original.reason}</p>
    ),
  },
  {
    accessorKey: "bookings.jobs.title",
    header: "Job",
    cell: ({ row }) => row.original.bookings?.jobs?.title || "N/A",
  },
  {
    accessorKey: "raiser.full_name",
    header: "Raised By",
    cell: ({ row }) => row.original.raiser?.full_name || "Unknown",
  },
  {
    accessorKey: "bookings.agreed_price",
    header: "Amount",
    cell: ({ row }) =>
      row.original.bookings?.agreed_price
        ? formatNaira(row.original.bookings.agreed_price)
        : "N/A",
  },
  {
    accessorKey: "status",
    header: "Status",
    cell: ({ row }) => (
      <Badge className={statusColors[row.original.status] || ""}>
        {row.original.status.replace(/_/g, " ")}
      </Badge>
    ),
  },
  {
    accessorKey: "created_at",
    header: "Raised",
    cell: ({ row }) => formatDate(row.original.created_at),
  },
  {
    id: "actions",
    cell: ({ row }) => (
      <Link href={`/disputes/${row.original.id}`}>
        <Button variant="ghost" size="sm">
          <Eye className="mr-2 h-4 w-4" />
          Review
        </Button>
      </Link>
    ),
  },
];

interface DisputesTableProps {
  disputes: DisputeRow[];
  totalCount: number;
  page: number;
  pageSize: number;
  currentStatus: string;
}

export function DisputesTable({
  disputes,
  totalCount,
  page,
  pageSize,
  currentStatus,
}: DisputesTableProps) {
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
    router.push(`/disputes?${params.toString()}`);
  };

  const handlePageChange = (newPage: number) => {
    const params = new URLSearchParams(searchParams.toString());
    params.set("page", newPage.toString());
    router.push(`/disputes?${params.toString()}`);
  };

  return (
    <DataTable
      columns={columns}
      data={disputes}
      totalCount={totalCount}
      page={page}
      pageSize={pageSize}
      onPageChange={handlePageChange}
      filterComponent={
        <Select value={currentStatus} onValueChange={(v) => updateFilter("status", v)}>
          <option value="">Open / Under Review</option>
          <option value="open">Open</option>
          <option value="under_review">Under Review</option>
          <option value="resolved_client_favor">Resolved (Client)</option>
          <option value="resolved_worker_favor">Resolved (Worker)</option>
          <option value="resolved_mutual">Resolved (Mutual)</option>
          <option value="closed">Closed</option>
        </Select>
      }
    />
  );
}
