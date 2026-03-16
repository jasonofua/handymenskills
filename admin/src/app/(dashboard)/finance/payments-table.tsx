"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { type ColumnDef } from "@tanstack/react-table";
import { DataTable } from "@/components/data-table/data-table";
import { Badge } from "@/components/ui/badge";
import { Select } from "@/components/ui/select";
import { formatDate, formatNaira } from "@/lib/format";
import { statusColors } from "@/lib/constants";

type PaymentRow = {
  id: string;
  amount: number;
  status: string;
  payment_type: string;
  payment_method: string | null;
  paystack_reference: string | null;
  created_at: string;
  bookings: { id: string; jobs: { title: string } | null } | null;
  payer: { full_name: string } | null;
};

const columns: ColumnDef<PaymentRow, unknown>[] = [
  {
    accessorKey: "paystack_reference",
    header: "Reference",
    cell: ({ row }) => (
      <span className="font-mono text-xs">{row.original.paystack_reference || "N/A"}</span>
    ),
  },
  {
    accessorKey: "payer.full_name",
    header: "Payer",
    cell: ({ row }) => row.original.payer?.full_name || "Unknown",
  },
  {
    accessorKey: "bookings.jobs.title",
    header: "Job",
    cell: ({ row }) => row.original.bookings?.jobs?.title || "N/A",
  },
  {
    accessorKey: "amount",
    header: "Amount",
    cell: ({ row }) => formatNaira(row.original.amount),
  },
  {
    accessorKey: "payment_type",
    header: "Type",
    cell: ({ row }) => row.original.payment_type?.replace(/_/g, " ") || "N/A",
  },
  {
    accessorKey: "payment_method",
    header: "Method",
    cell: ({ row }) => row.original.payment_method || "N/A",
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
    header: "Date",
    cell: ({ row }) => formatDate(row.original.created_at),
  },
];

interface PaymentsTableProps {
  payments: PaymentRow[];
  totalCount: number;
  page: number;
  pageSize: number;
  currentStatus: string;
}

export function PaymentsTable({
  payments,
  totalCount,
  page,
  pageSize,
  currentStatus,
}: PaymentsTableProps) {
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
    router.push(`/finance?${params.toString()}`);
  };

  const handlePageChange = (newPage: number) => {
    const params = new URLSearchParams(searchParams.toString());
    params.set("page", newPage.toString());
    router.push(`/finance?${params.toString()}`);
  };

  return (
    <DataTable
      columns={columns}
      data={payments}
      totalCount={totalCount}
      page={page}
      pageSize={pageSize}
      onPageChange={handlePageChange}
      filterComponent={
        <Select value={currentStatus} onValueChange={(v) => updateFilter("status", v)}>
          <option value="">All Statuses</option>
          <option value="pending">Pending</option>
          <option value="processing">Processing</option>
          <option value="success">Success</option>
          <option value="failed">Failed</option>
          <option value="refunded">Refunded</option>
        </Select>
      }
    />
  );
}
