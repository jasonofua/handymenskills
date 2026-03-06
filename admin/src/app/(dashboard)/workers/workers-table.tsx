"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { type ColumnDef } from "@tanstack/react-table";
import { DataTable } from "@/components/data-table/data-table";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Select } from "@/components/ui/select";
import { Eye } from "lucide-react";
import { formatDate } from "@/lib/format";
import { statusColors } from "@/lib/constants";
import type { WorkerProfile } from "@/types";
import Link from "next/link";

type WorkerRow = WorkerProfile & {
  profiles: {
    id: string;
    full_name: string;
    email: string | null;
    phone: string;
    avatar_url: string | null;
    city: string | null;
    state: string | null;
  };
};

const columns: ColumnDef<WorkerRow, unknown>[] = [
  {
    accessorKey: "profiles.full_name",
    header: "Worker",
    cell: ({ row }) => {
      const profile = row.original.profiles;
      const initials = profile?.full_name
        ? profile.full_name.split(" ").map((n) => n[0]).join("").toUpperCase().slice(0, 2)
        : "?";
      return (
        <div className="flex items-center gap-3">
          <Avatar className="h-8 w-8">
            <AvatarImage src={profile?.avatar_url || undefined} />
            <AvatarFallback className="text-xs">{initials}</AvatarFallback>
          </Avatar>
          <div>
            <p className="font-medium">{profile?.full_name}</p>
            <p className="text-xs text-muted-foreground">{profile?.email}</p>
          </div>
        </div>
      );
    },
  },
  {
    accessorKey: "years_of_experience",
    header: "Experience",
    cell: ({ row }) => `${row.original.years_of_experience || 0} years`,
  },
  {
    accessorKey: "verification_status",
    header: "Status",
    cell: ({ row }) => (
      <Badge className={statusColors[row.original.verification_status] || ""}>
        {row.original.verification_status}
      </Badge>
    ),
  },
  {
    accessorKey: "rating_average",
    header: "Rating",
    cell: ({ row }) =>
      row.original.rating_average
        ? `${row.original.rating_average.toFixed(1)} (${row.original.rating_count})`
        : "N/A",
  },
  {
    accessorKey: "created_at",
    header: "Submitted",
    cell: ({ row }) => formatDate(row.original.created_at),
  },
  {
    id: "actions",
    cell: ({ row }) => (
      <Link href={`/workers/${row.original.id}`}>
        <Button variant="ghost" size="sm">
          <Eye className="mr-2 h-4 w-4" />
          Review
        </Button>
      </Link>
    ),
  },
];

interface WorkersTableProps {
  workers: WorkerRow[];
  totalCount: number;
  page: number;
  pageSize: number;
  currentStatus: string;
}

export function WorkersTable({
  workers,
  totalCount,
  page,
  pageSize,
  currentStatus,
}: WorkersTableProps) {
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
    router.push(`/workers?${params.toString()}`);
  };

  const handlePageChange = (newPage: number) => {
    const params = new URLSearchParams(searchParams.toString());
    params.set("page", newPage.toString());
    router.push(`/workers?${params.toString()}`);
  };

  return (
    <DataTable
      columns={columns}
      data={workers}
      totalCount={totalCount}
      page={page}
      pageSize={pageSize}
      onPageChange={handlePageChange}
      filterComponent={
        <Select
          value={currentStatus}
          onValueChange={(v) => updateFilter("status", v)}
        >
          <option value="">All Statuses</option>
          <option value="pending">Pending</option>
          <option value="verified">Verified</option>
          <option value="rejected">Rejected</option>
          <option value="unverified">Unverified</option>
        </Select>
      }
    />
  );
}
