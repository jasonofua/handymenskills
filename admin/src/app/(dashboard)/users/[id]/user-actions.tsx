"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { useToast } from "@/components/ui/toast";
import { banUser, unbanUser, suspendUser, addStrike } from "../actions";
import type { Profile } from "@/types";
import { Ban, ShieldOff, AlertTriangle, UserCheck, Loader2 } from "lucide-react";

export function UserActions({ user }: { user: Profile }) {
  const { toast } = useToast();
  const [loading, setLoading] = useState<string | null>(null);

  const handleAction = async (action: string) => {
    setLoading(action);
    try {
      let result;
      switch (action) {
        case "ban":
          result = await banUser(user.id);
          break;
        case "unban":
          result = await unbanUser(user.id);
          break;
        case "suspend":
          result = await suspendUser(user.id);
          break;
        case "strike":
          result = await addStrike(user.id);
          break;
        default:
          return;
      }

      if (result.error) {
        toast({ title: "Error", description: result.error, variant: "destructive" });
      } else {
        toast({ title: "Success", description: `Action "${action}" completed successfully.`, variant: "success" });
      }
    } catch {
      toast({ title: "Error", description: "An unexpected error occurred.", variant: "destructive" });
    } finally {
      setLoading(null);
    }
  };

  return (
    <div className="space-y-2">
      <p className="text-sm font-medium text-muted-foreground">Actions</p>

      {user.account_status === "banned" ? (
        <Button
          variant="outline"
          className="w-full justify-start"
          onClick={() => handleAction("unban")}
          disabled={loading !== null}
        >
          {loading === "unban" ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <UserCheck className="mr-2 h-4 w-4" />}
          Unban User
        </Button>
      ) : (
        <>
          <Button
            variant="outline"
            className="w-full justify-start"
            onClick={() => handleAction("suspend")}
            disabled={loading !== null || user.account_status === "suspended"}
          >
            {loading === "suspend" ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <ShieldOff className="mr-2 h-4 w-4" />}
            Suspend User
          </Button>
          <Button
            variant="outline"
            className="w-full justify-start text-amber-600 hover:text-amber-700"
            onClick={() => handleAction("strike")}
            disabled={loading !== null}
          >
            {loading === "strike" ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <AlertTriangle className="mr-2 h-4 w-4" />}
            Add Strike ({user.strikes}/3)
          </Button>
          <Button
            variant="destructive"
            className="w-full justify-start"
            onClick={() => handleAction("ban")}
            disabled={loading !== null}
          >
            {loading === "ban" ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Ban className="mr-2 h-4 w-4" />}
            Ban User
          </Button>
        </>
      )}
    </div>
  );
}
