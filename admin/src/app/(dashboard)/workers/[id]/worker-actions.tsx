"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { useToast } from "@/components/ui/toast";
import { verifyWorker, rejectWorker } from "../actions";
import { CheckCircle, XCircle, Loader2 } from "lucide-react";

export function WorkerVerificationActions({
  workerProfileId,
}: {
  workerProfileId: string;
}) {
  const [notes, setNotes] = useState("");
  const [loading, setLoading] = useState<string | null>(null);
  const { toast } = useToast();
  const router = useRouter();

  const handleVerify = async () => {
    setLoading("verify");
    try {
      const result = await verifyWorker(workerProfileId, notes);
      if (result.error) {
        toast({ title: "Error", description: result.error, variant: "destructive" });
      } else {
        toast({ title: "Worker Verified", description: "The worker profile has been approved.", variant: "success" });
        router.push("/workers");
      }
    } catch {
      toast({ title: "Error", description: "An unexpected error occurred.", variant: "destructive" });
    } finally {
      setLoading(null);
    }
  };

  const handleReject = async () => {
    if (!notes.trim()) {
      toast({ title: "Notes Required", description: "Please provide rejection notes.", variant: "destructive" });
      return;
    }
    setLoading("reject");
    try {
      const result = await rejectWorker(workerProfileId, notes);
      if (result.error) {
        toast({ title: "Error", description: result.error, variant: "destructive" });
      } else {
        toast({ title: "Worker Rejected", description: "The worker profile has been rejected.", variant: "success" });
        router.push("/workers");
      }
    } catch {
      toast({ title: "Error", description: "An unexpected error occurred.", variant: "destructive" });
    } finally {
      setLoading(null);
    }
  };

  return (
    <div className="space-y-4">
      <div className="space-y-2">
        <Label htmlFor="notes">Notes</Label>
        <Textarea
          id="notes"
          placeholder="Add notes about this verification decision (required for rejection)..."
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          rows={3}
        />
      </div>
      <div className="flex gap-3">
        <Button
          onClick={handleVerify}
          disabled={loading !== null}
          className="bg-emerald-600 hover:bg-emerald-700"
        >
          {loading === "verify" ? (
            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
          ) : (
            <CheckCircle className="mr-2 h-4 w-4" />
          )}
          Approve
        </Button>
        <Button
          variant="destructive"
          onClick={handleReject}
          disabled={loading !== null}
        >
          {loading === "reject" ? (
            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
          ) : (
            <XCircle className="mr-2 h-4 w-4" />
          )}
          Reject
        </Button>
      </div>
    </div>
  );
}
