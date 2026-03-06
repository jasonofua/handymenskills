"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { type ColumnDef } from "@tanstack/react-table";
import { DataTable } from "@/components/data-table/data-table";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Button } from "@/components/ui/button";
import { Select } from "@/components/ui/select";
import { MoreHorizontal, Eye } from "lucide-react";
import { formatDate } from "@/lib/format";
import { statusColors, roleColors } from "@/lib/constants";
import type { Profile } from "@/types";
import Link from "next/link";

const columns: ColumnDef<Profile, unknown>[] = [
  {
    accessorKey: "full_name",
    header: "Name",
    cell: ({ row }) => {
      const profile = row.original;
      const initials = profile.full_name
        ? profile.full_name
            .split(" ")
            .map((n) => n[0])
            .join("")
            .toUpperCase()
            .slice(0, 2)
        : "?";
      return (
        <div className="flex items-center gap-3">
          <Avatar className="h-8 w-8">
            <AvatarImage src={profile.avatar_url || undefined} />
            <AvatarFallback className="text-xs">{initials}</AvatarFallback>
          </Avatar>
          <div>
            <p className="font-medium">{profile.full_name}</p>
            <p className="text-xs text-muted-foreground">{profile.email}</p>
          </div>
        </div>
      );
    },
  },
  {
    accessorKey: "phone",
    header: "Phone",
  },
  {
    accessorKey: "role",
    header: "Role",
    cell: ({ row }) => (
      <Badge className={roleColors[row.original.role] || ""}>
        {row.original.role}
      </Badge>
    ),
  },
  {
    accessorKey: "account_status",
    header: "Status",
    cell: ({ row }) => (
      <Badge className={statusColors[row.original.account_status] || ""}>
        {row.original.account_status}
      </Badge>
    ),
  },
  {
    accessorKey: "strikes",
    header: "Strikes",
    cell: ({ row }) => (
      <span className={row.original.strikes > 0 ? "font-bold text-destructive" : ""}>
        {row.original.strikes}
      </span>
    ),
  },
  {
    accessorKey: "city",
    header: "City",
    cell: ({ row }) => row.original.city || "-",
  },
  {
    accessorKey: "created_at",
    header: "Joined",
    cell: ({ row }) => formatDate(row.original.created_at),
  },
  {
    id: "actions",
    cell: ({ row }) => (
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" size="icon" className="h-8 w-8">
            <MoreHorizontal className="h-4 w-4" />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent>
          <Link href={`/users/${row.original.id}`}>
            <DropdownMenuItem>
              <Eye className="mr-2 h-4 w-4" />
              View Details
            </DropdownMenuItem>
          </Link>
        </DropdownMenuContent>
      </DropdownMenu>
    ),
  },
];

interface UsersTableProps {
  users: Profile[];
  totalCount: number;
  page: number;
  pageSize: number;
  currentStatus: string;
  currentRole: string;
}

export function UsersTable({
  users,
  totalCount,
  page,
  pageSize,
  currentStatus,
  currentRole,
}: UsersTableProps) {
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
    router.push(`/users?${params.toString()}`);
  };

  const handlePageChange = (newPage: number) => {
    const params = new URLSearchParams(searchParams.toString());
    params.set("page", newPage.toString());
    router.push(`/users?${params.toString()}`);
  };

  return (
    <DataTable
      columns={columns}
      data={users}
      totalCount={totalCount}
      page={page}
      pageSize={pageSize}
      onPageChange={handlePageChange}
      searchKey="full_name"
      searchPlaceholder="Search users..."
      filterComponent={
        <div className="flex gap-2">
          <Select
            value={currentRole}
            onValueChange={(v) => updateFilter("role", v)}
          >
            <option value="">All Roles</option>
            <option value="client">Client</option>
            <option value="worker">Worker</option>
            <option value="admin">Admin</option>
          </Select>
          <Select
            value={currentStatus}
            onValueChange={(v) => updateFilter("status", v)}
          >
            <option value="">All Statuses</option>
            <option value="active">Active</option>
            <option value="suspended">Suspended</option>
            <option value="banned">Banned</option>
            <option value="deactivated">Deactivated</option>
          </Select>
        </div>
      }
    />
  );
}
