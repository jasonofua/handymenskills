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

type BookingRow = {
  id: string;
  booking_status: string;
  agreed_price: number;
  platform_fee: number;
  worker_payout: number;
  created_at: string;
  jobs: { title: string } | null;
  client: { full_name: string } | null;
  worker: { full_name: string } | null;
};

const columns: ColumnDef<BookingRow, unknown>[] = [
  {
    accessorKey: "jobs.title",
    header: "Job",
    cell: ({ row }) => (
      <div>
        <p className="font-medium">{row.original.jobs?.title || "Untitled"}</p>
      </div>
    ),
  },
  {
    accessorKey: "client.full_name",
    header: "Client",
    cell: ({ row }) => row.original.client?.full_name || "Unknown",
  },
  {
    accessorKey: "worker.full_name",
    header: "Worker",
    cell: ({ row }) => row.original.worker?.full_name || "Unknown",
  },
  {
    accessorKey: "agreed_price",
    header: "Amount",
    cell: ({ row }) => formatNaira(row.original.agreed_price),
  },
  {
    accessorKey: "booking_status",
    header: "Status",
    cell: ({ row }) => (
      <Badge className={statusColors[row.original.booking_status] || ""}>
        {row.original.booking_status.replace(/_/g, " ")}
      </Badge>
    ),
  },
  {
    accessorKey: "created_at",
    header: "Created",
    cell: ({ row }) => formatDate(row.original.created_at),
  },
  {
    id: "actions",
    cell: ({ row }) => (
      <Link href={`/bookings/${row.original.id}`}>
        <Button variant="ghost" size="sm">
          <Eye className="mr-2 h-4 w-4" />
          View
        </Button>
      </Link>
    ),
  },
];

interface BookingsTableProps {
  bookings: BookingRow[];
  totalCount: number;
  page: number;
  pageSize: number;
  currentStatus: string;
}

export function BookingsTable({
  bookings,
  totalCount,
  page,
  pageSize,
  currentStatus,
}: BookingsTableProps) {
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
    router.push(`/bookings?${params.toString()}`);
  };

  const handlePageChange = (newPage: number) => {
    const params = new URLSearchParams(searchParams.toString());
    params.set("page", newPage.toString());
    router.push(`/bookings?${params.toString()}`);
  };

  return (
    <DataTable
      columns={columns}
      data={bookings}
      totalCount={totalCount}
      page={page}
      pageSize={pageSize}
      onPageChange={handlePageChange}
      filterComponent={
        <Select value={currentStatus} onValueChange={(v) => updateFilter("status", v)}>
          <option value="">All Statuses</option>
          <option value="pending">Pending</option>
          <option value="accepted">Accepted</option>
          <option value="in_progress">In Progress</option>
          <option value="completed">Completed</option>
          <option value="cancelled">Cancelled</option>
          <option value="disputed">Disputed</option>
        </Select>
      }
    />
  );
}
