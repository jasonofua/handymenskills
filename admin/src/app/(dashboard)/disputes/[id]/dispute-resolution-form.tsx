"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select } from "@/components/ui/select";
import { useToast } from "@/components/ui/toast";
import { resolveDispute } from "../actions";
import { Loader2, Gavel } from "lucide-react";
import { formatNaira } from "@/lib/format";

export function DisputeResolutionForm({
  disputeId,
  agreedPrice,
}: {
  disputeId: string;
  agreedPrice: number;
}) {
  const [notes, setNotes] = useState("");
  const [resolution, setResolution] = useState<string>("");
  const [refundAmount, setRefundAmount] = useState<string>("");
  const [loading, setLoading] = useState(false);
  const { toast } = useToast();
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!resolution) {
      toast({ title: "Error", description: "Please select a resolution.", variant: "destructive" });
      return;
    }
    if (!notes.trim()) {
      toast({ title: "Error", description: "Resolution notes are required.", variant: "destructive" });
      return;
    }

    setLoading(true);
    try {
      const refund = refundAmount ? parseFloat(refundAmount) : null;
      const result = await resolveDispute(
        disputeId,
        resolution as "resolved_client_favor" | "resolved_worker_favor" | "resolved_mutual",
        notes,
        refund
      );
      if (result.error) {
        toast({ title: "Error", description: result.error, variant: "destructive" });
      } else {
        toast({ title: "Dispute Resolved", description: "The dispute has been resolved.", variant: "success" });
        router.push("/disputes");
      }
    } catch {
      toast({ title: "Error", description: "An unexpected error occurred.", variant: "destructive" });
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="space-y-2">
        <Label htmlFor="resolution">Resolution Decision</Label>
        <Select
          id="resolution"
          value={resolution}
          onValueChange={setResolution}
        >
          <option value="">Select resolution...</option>
          <option value="resolved_client_favor">In Favor of Client</option>
          <option value="resolved_worker_favor">In Favor of Worker</option>
          <option value="resolved_mutual">Mutual Resolution</option>
        </Select>
      </div>

      {(resolution === "resolved_client_favor" || resolution === "resolved_mutual") && (
        <div className="space-y-2">
          <Label htmlFor="refund">Refund Amount (max {formatNaira(agreedPrice)})</Label>
          <Input
            id="refund"
            type="number"
            step="0.01"
            min="0"
            max={agreedPrice}
            placeholder="0.00"
            value={refundAmount}
            onChange={(e) => setRefundAmount(e.target.value)}
          />
        </div>
      )}

      <div className="space-y-2">
        <Label htmlFor="dispute-notes">Resolution Notes</Label>
        <Textarea
          id="dispute-notes"
          placeholder="Describe the resolution decision, evidence reviewed, and any actions taken..."
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          rows={4}
        />
      </div>

      <Button type="submit" disabled={loading || !resolution}>
        {loading ? (
          <Loader2 className="mr-2 h-4 w-4 animate-spin" />
        ) : (
          <Gavel className="mr-2 h-4 w-4" />
        )}
        Resolve Dispute
      </Button>
    </form>
  );
}
