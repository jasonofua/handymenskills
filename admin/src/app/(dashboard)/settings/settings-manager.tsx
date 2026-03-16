"use client";

import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { useToast } from "@/components/ui/toast";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { updateSetting, createSetting } from "./actions";
import type { SystemSetting } from "@/types";
import { Save, Plus, Loader2, Settings, Users } from "lucide-react";
import { formatDate } from "@/lib/format";

function formatSettingKey(key: string): string {
  return key
    .split("_")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
}

export function SettingsManager({
  initialSettings,
  admins,
}: {
  initialSettings: SystemSetting[];
  admins: { id: string; full_name: string; email: string | null; created_at: string }[];
}) {
  const [editValues, setEditValues] = useState<Record<string, string>>({});
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [newKey, setNewKey] = useState("");
  const [newValue, setNewValue] = useState("");
  const [newDesc, setNewDesc] = useState("");
  const [loading, setLoading] = useState<string | null>(null);
  const { toast } = useToast();

  const handleUpdateSetting = async (key: string) => {
    const value = editValues[key];
    if (value === undefined) return;

    setLoading(key);
    try {
      const result = await updateSetting(key, value);
      if (result.error) {
        toast({ title: "Error", description: result.error, variant: "destructive" });
      } else {
        toast({ title: "Setting Updated", description: `"${key}" has been updated.`, variant: "success" });
        setEditValues((prev) => {
          const next = { ...prev };
          delete next[key];
          return next;
        });
      }
    } catch {
      toast({ title: "Error", description: "An unexpected error occurred.", variant: "destructive" });
    } finally {
      setLoading(null);
    }
  };

  const handleCreateSetting = async () => {
    if (!newKey.trim() || !newValue.trim()) {
      toast({ title: "Error", description: "Key and value are required.", variant: "destructive" });
      return;
    }
    setLoading("create");
    try {
      const result = await createSetting(newKey, newValue, newDesc);
      if (result.error) {
        toast({ title: "Error", description: result.error, variant: "destructive" });
      } else {
        toast({ title: "Setting Created", variant: "success" });
        setShowAddDialog(false);
        setNewKey("");
        setNewValue("");
        setNewDesc("");
      }
    } catch {
      toast({ title: "Error", description: "An unexpected error occurred.", variant: "destructive" });
    } finally {
      setLoading(null);
    }
  };

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <div className="flex items-center gap-2">
            <Settings className="h-5 w-5" />
            <CardTitle className="text-lg">System Settings</CardTitle>
          </div>
          <Button size="sm" onClick={() => setShowAddDialog(true)}>
            <Plus className="mr-2 h-4 w-4" />
            Add Setting
          </Button>
        </CardHeader>
        <CardContent>
          {initialSettings.length === 0 ? (
            <p className="text-sm text-muted-foreground">No system settings configured.</p>
          ) : (
            <div className="space-y-4">
              {initialSettings.map((setting) => (
                <div key={setting.id} className="space-y-2">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium">{formatSettingKey(setting.key)}</p>
                      {setting.description && (
                        <p className="text-xs text-muted-foreground">{setting.description}</p>
                      )}
                    </div>
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => handleUpdateSetting(setting.key)}
                      disabled={editValues[setting.key] === undefined || loading === setting.key}
                    >
                      {loading === setting.key ? (
                        <Loader2 className="mr-2 h-3.5 w-3.5 animate-spin" />
                      ) : (
                        <Save className="mr-2 h-3.5 w-3.5" />
                      )}
                      Save
                    </Button>
                  </div>
                  <Input
                    value={editValues[setting.key] !== undefined ? editValues[setting.key] : setting.value}
                    onChange={(e) =>
                      setEditValues((prev) => ({ ...prev, [setting.key]: e.target.value }))
                    }
                  />
                  <Separator />
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Users className="h-5 w-5" />
            <CardTitle className="text-lg">Admin Users</CardTitle>
          </div>
        </CardHeader>
        <CardContent>
          {admins.length === 0 ? (
            <p className="text-sm text-muted-foreground">No admin users found.</p>
          ) : (
            <div className="space-y-3">
              {admins.map((admin) => (
                <div key={admin.id} className="flex items-center justify-between rounded-lg border p-3">
                  <div>
                    <p className="font-medium">{admin.full_name}</p>
                    <p className="text-xs text-muted-foreground">{admin.email}</p>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant="default">Admin</Badge>
                    <span className="text-xs text-muted-foreground">
                      Since {formatDate(admin.created_at)}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      <Dialog open={showAddDialog} onOpenChange={setShowAddDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add Setting</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Key</Label>
              <Input
                value={newKey}
                onChange={(e) => setNewKey(e.target.value)}
                placeholder="e.g. platform_commission_rate"
              />
            </div>
            <div className="space-y-2">
              <Label>Value</Label>
              <Input
                value={newValue}
                onChange={(e) => setNewValue(e.target.value)}
                placeholder="e.g. 0.15"
              />
            </div>
            <div className="space-y-2">
              <Label>Description</Label>
              <Input
                value={newDesc}
                onChange={(e) => setNewDesc(e.target.value)}
                placeholder="What this setting controls"
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowAddDialog(false)}>
              Cancel
            </Button>
            <Button onClick={handleCreateSetting} disabled={loading === "create"}>
              {loading === "create" && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              Create Setting
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
