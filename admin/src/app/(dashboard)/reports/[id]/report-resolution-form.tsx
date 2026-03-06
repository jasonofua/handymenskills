"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { useToast } from "@/components/ui/toast";
import { resolveReport } from "../actions";
import { CheckCircle, XCircle, Loader2 } from "lucide-react";

export function ReportResolutionForm({ reportId }: { reportId: string }) {
  const [notes, setNotes] = useState("");
  const [loading, setLoading] = useState<string | null>(null);
  const { toast } = useToast();
  const router = useRouter();

  const handleResolve = async (resolution: "resolved" | "dismissed") => {
    if (!notes.trim()) {
      toast({ title: "Notes Required", description: "Please provide resolution notes.", variant: "destructive" });
      return;
    }
    setLoading(resolution);
    try {
      const result = await resolveReport(reportId, resolution, notes);
      if (result.error) {
        toast({ title: "Error", description: result.error, variant: "destructive" });
      } else {
        toast({
          title: resolution === "resolved" ? "Report Resolved" : "Report Dismissed",
          description: resolution === "resolved"
            ? "The report has been resolved. A strike has been added to the reported user."
            : "The report has been dismissed.",
          variant: "success",
        });
        router.push("/reports");
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
        <Label htmlFor="resolution-notes">Resolution Notes</Label>
        <Textarea
          id="resolution-notes"
          placeholder="Describe the resolution decision and any actions taken..."
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          rows={4}
        />
      </div>
      <div className="flex gap-3">
        <Button
          onClick={() => handleResolve("resolved")}
          disabled={loading !== null}
          className="bg-emerald-600 hover:bg-emerald-700"
        >
          {loading === "resolved" ? (
            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
          ) : (
            <CheckCircle className="mr-2 h-4 w-4" />
          )}
          Resolve (Add Strike)
        </Button>
        <Button
          variant="outline"
          onClick={() => handleResolve("dismissed")}
          disabled={loading !== null}
        >
          {loading === "dismissed" ? (
            <Loader2 className="mr-2 h-4 w-4 animate-spin" />
          ) : (
            <XCircle className="mr-2 h-4 w-4" />
          )}
          Dismiss
        </Button>
      </div>
    </div>
  );
}
