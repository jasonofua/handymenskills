"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { type ColumnDef } from "@tanstack/react-table";
import { DataTable } from "@/components/data-table/data-table";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Select } from "@/components/ui/select";
import { formatDate, formatNaira } from "@/lib/format";
import { statusColors } from "@/lib/constants";
import { useToast } from "@/components/ui/toast";
import { processPayout } from "./actions";
import { Loader2, Send } from "lucide-react";
import { useState } from "react";

type PayoutRow = {
  id: string;
  amount: number;
  payout_status: string;
  bank_name: string | null;
  account_number: string | null;
  account_name: string | null;
  reference: string | null;
  processed_at: string | null;
  created_at: string;
  worker: { full_name: string } | null;
};

function ProcessButton({ payoutId }: { payoutId: string }) {
  const [loading, setLoading] = useState(false);
  const { toast } = useToast();

  const handleProcess = async () => {
    setLoading(true);
    try {
      const result = await processPayout(payoutId);
      if (result.error) {
        toast({ title: "Error", description: result.error, variant: "destructive" });
      } else {
        toast({ title: "Payout Processed", description: "The payout has been marked as completed.", variant: "success" });
      }
    } catch {
      toast({ title: "Error", description: "Failed to process payout.", variant: "destructive" });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Button size="sm" onClick={handleProcess} disabled={loading}>
      {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Send className="mr-2 h-4 w-4" />}
      Process
    </Button>
  );
}

const columns: ColumnDef<PayoutRow, unknown>[] = [
  {
    accessorKey: "worker.full_name",
    header: "Worker",
    cell: ({ row }) => row.original.worker?.full_name || "Unknown",
  },
  {
    accessorKey: "amount",
    header: "Amount",
    cell: ({ row }) => formatNaira(row.original.amount),
  },
  {
    accessorKey: "bank_name",
    header: "Bank",
    cell: ({ row }) => row.original.bank_name || "N/A",
  },
  {
    accessorKey: "account_number",
    header: "Account",
    cell: ({ row }) => row.original.account_number || "N/A",
  },
  {
    accessorKey: "account_name",
    header: "Account Name",
    cell: ({ row }) => row.original.account_name || "N/A",
  },
  {
    accessorKey: "payout_status",
    header: "Status",
    cell: ({ row }) => (
      <Badge className={statusColors[row.original.payout_status] || ""}>
        {row.original.payout_status}
      </Badge>
    ),
  },
  {
    accessorKey: "created_at",
    header: "Date",
    cell: ({ row }) => formatDate(row.original.created_at),
  },
  {
    id: "actions",
    cell: ({ row }) =>
      row.original.payout_status === "pending" ? (
        <ProcessButton payoutId={row.original.id} />
      ) : null,
  },
];

interface PayoutsTableProps {
  payouts: PayoutRow[];
  totalCount: number;
  page: number;
  pageSize: number;
  currentStatus: string;
}

export function PayoutsTable({
  payouts,
  totalCount,
  page,
  pageSize,
  currentStatus,
}: PayoutsTableProps) {
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
    router.push(`/finance/payouts?${params.toString()}`);
  };

  const handlePageChange = (newPage: number) => {
    const params = new URLSearchParams(searchParams.toString());
    params.set("page", newPage.toString());
    router.push(`/finance/payouts?${params.toString()}`);
  };

  return (
    <DataTable
      columns={columns}
      data={payouts}
      totalCount={totalCount}
      page={page}
      pageSize={pageSize}
      onPageChange={handlePageChange}
      filterComponent={
        <Select value={currentStatus} onValueChange={(v) => updateFilter("status", v)}>
          <option value="">All Statuses</option>
          <option value="pending">Pending</option>
          <option value="processing">Processing</option>
          <option value="completed">Completed</option>
          <option value="failed">Failed</option>
        </Select>
      }
    />
  );
}
