"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { type ColumnDef } from "@tanstack/react-table";
import { DataTable } from "@/components/data-table/data-table";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Select } from "@/components/ui/select";
import { Eye } from "lucide-react";
import { formatDate, formatNaira } from "@/lib/format";
import { statusColors, urgencyColors } from "@/lib/constants";
import Link from "next/link";

type JobRow = {
  id: string;
  title: string;
  status: string;
  urgency: string;
  budget_min: number | null;
  budget_max: number | null;
  city: string | null;
  created_at: string;
  profiles: { full_name: string; avatar_url: string | null } | null;
  categories: { name: string } | null;
};

const columns: ColumnDef<JobRow, unknown>[] = [
  {
    accessorKey: "title",
    header: "Title",
    cell: ({ row }) => (
      <div>
        <p className="font-medium">{row.original.title}</p>
        <p className="text-xs text-muted-foreground">
          by {row.original.profiles?.full_name || "Unknown"}
        </p>
      </div>
    ),
  },
  {
    accessorKey: "categories.name",
    header: "Category",
    cell: ({ row }) => row.original.categories?.name || "-",
  },
  {
    accessorKey: "status",
    header: "Status",
    cell: ({ row }) => (
      <Badge className={statusColors[row.original.status] || ""}>
        {(row.original.status || "unknown").replace(/_/g, " ")}
      </Badge>
    ),
  },
  {
    accessorKey: "urgency",
    header: "Urgency",
    cell: ({ row }) => (
      <Badge className={urgencyColors[row.original.urgency] || ""}>
        {row.original.urgency || "normal"}
      </Badge>
    ),
  },
  {
    accessorKey: "budget_min",
    header: "Budget",
    cell: ({ row }) => {
      const min = row.original.budget_min;
      const max = row.original.budget_max;
      if (!min && !max) return "-";
      if (min && max) return `${formatNaira(min)} - ${formatNaira(max)}`;
      return formatNaira(min || max || 0);
    },
  },
  {
    accessorKey: "city",
    header: "Location",
    cell: ({ row }) => row.original.city || "-",
  },
  {
    accessorKey: "created_at",
    header: "Posted",
    cell: ({ row }) => formatDate(row.original.created_at),
  },
  {
    id: "actions",
    cell: ({ row }) => (
      <Link href={`/jobs/${row.original.id}`}>
        <Button variant="ghost" size="sm">
          <Eye className="mr-2 h-4 w-4" />
          View
        </Button>
      </Link>
    ),
  },
];

interface JobsTableProps {
  jobs: JobRow[];
  totalCount: number;
  page: number;
  pageSize: number;
  currentStatus: string;
  currentUrgency: string;
  categories: { id: string; name: string }[];
}

export function JobsTable({
  jobs,
  totalCount,
  page,
  pageSize,
  currentStatus,
  currentUrgency,
}: JobsTableProps) {
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
    router.push(`/jobs?${params.toString()}`);
  };

  const handlePageChange = (newPage: number) => {
    const params = new URLSearchParams(searchParams.toString());
    params.set("page", newPage.toString());
    router.push(`/jobs?${params.toString()}`);
  };

  return (
    <DataTable
      columns={columns}
      data={jobs}
      totalCount={totalCount}
      page={page}
      pageSize={pageSize}
      onPageChange={handlePageChange}
      searchKey="title"
      searchPlaceholder="Search jobs..."
      filterComponent={
        <div className="flex gap-2">
          <Select value={currentStatus} onValueChange={(v) => updateFilter("status", v)}>
            <option value="">All Statuses</option>
            <option value="draft">Draft</option>
            <option value="open">Open</option>
            <option value="assigned">Assigned</option>
            <option value="in_progress">In Progress</option>
            <option value="completed">Completed</option>
            <option value="cancelled">Cancelled</option>
            <option value="disputed">Disputed</option>
          </Select>
          <Select value={currentUrgency} onValueChange={(v) => updateFilter("urgency", v)}>
            <option value="">All Urgency</option>
            <option value="low">Low</option>
            <option value="normal">Normal</option>
            <option value="urgent">Urgent</option>
            <option value="emergency">Emergency</option>
          </Select>
        </div>
      }
    />
  );
}
