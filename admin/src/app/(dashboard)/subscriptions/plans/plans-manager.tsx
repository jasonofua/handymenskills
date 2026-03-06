"use client";

import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardFooter } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Textarea } from "@/components/ui/textarea";
import { Select } from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { useToast } from "@/components/ui/toast";
import { createPlan, updatePlan } from "./actions";
import { formatNaira } from "@/lib/format";
import type { SubscriptionPlan } from "@/types";
import { Plus, Pencil, Loader2 } from "lucide-react";

export function PlansManager({ initialPlans }: { initialPlans: SubscriptionPlan[] }) {
  const [showDialog, setShowDialog] = useState(false);
  const [editPlan, setEditPlan] = useState<SubscriptionPlan | null>(null);
  const [loading, setLoading] = useState(false);
  const { toast } = useToast();

  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [price, setPrice] = useState("");
  const [interval, setInterval] = useState("monthly");

  const openDialog = (plan?: SubscriptionPlan) => {
    if (plan) {
      setEditPlan(plan);
      setName(plan.name);
      setDescription(plan.description || "");
      setPrice(plan.price.toString());
      setInterval(plan.interval);
    } else {
      setEditPlan(null);
      setName("");
      setDescription("");
      setPrice("");
      setInterval("monthly");
    }
    setShowDialog(true);
  };

  const handleSave = async () => {
    if (!name.trim() || !price) {
      toast({ title: "Error", description: "Name and price are required.", variant: "destructive" });
      return;
    }

    setLoading(true);
    try {
      if (editPlan) {
        const result = await updatePlan(editPlan.id, {
          name,
          description,
          price: parseFloat(price),
          interval,
          is_active: editPlan.is_active,
        });
        if (result.error) {
          toast({ title: "Error", description: result.error, variant: "destructive" });
        } else {
          toast({ title: "Plan Updated", variant: "success" });
          setShowDialog(false);
        }
      } else {
        const result = await createPlan({
          name,
          description,
          price: parseFloat(price),
          interval,
        });
        if (result.error) {
          toast({ title: "Error", description: result.error, variant: "destructive" });
        } else {
          toast({ title: "Plan Created", variant: "success" });
          setShowDialog(false);
        }
      }
    } catch {
      toast({ title: "Error", description: "An unexpected error occurred.", variant: "destructive" });
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <div className="flex justify-end">
        <Button onClick={() => openDialog()}>
          <Plus className="mr-2 h-4 w-4" />
          Add Plan
        </Button>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {initialPlans.length === 0 ? (
          <p className="col-span-full text-center text-muted-foreground">No plans configured.</p>
        ) : (
          initialPlans.map((plan) => (
            <Card key={plan.id}>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle className="text-lg">{plan.name}</CardTitle>
                  <Badge variant={plan.is_active ? "success" : "secondary"}>
                    {plan.is_active ? "Active" : "Inactive"}
                  </Badge>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  <p className="text-3xl font-bold">
                    {formatNaira(plan.price)}
                    <span className="text-sm font-normal text-muted-foreground">
                      /{plan.interval}
                    </span>
                  </p>
                  {plan.description && (
                    <p className="text-sm text-muted-foreground">{plan.description}</p>
                  )}
                  {plan.features && (
                    <div className="mt-3 space-y-1">
                      {Object.entries(plan.features).map(([key, value]) => (
                        <p key={key} className="text-sm">
                          <span className="font-medium">{key}:</span> {String(value)}
                        </p>
                      ))}
                    </div>
                  )}
                </div>
              </CardContent>
              <CardFooter>
                <Button variant="outline" size="sm" onClick={() => openDialog(plan)}>
                  <Pencil className="mr-2 h-3.5 w-3.5" />
                  Edit
                </Button>
              </CardFooter>
            </Card>
          ))
        )}
      </div>

      <Dialog open={showDialog} onOpenChange={setShowDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editPlan ? "Edit Plan" : "New Plan"}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Plan Name</Label>
              <Input value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Pro" />
            </div>
            <div className="space-y-2">
              <Label>Price (NGN)</Label>
              <Input
                type="number"
                value={price}
                onChange={(e) => setPrice(e.target.value)}
                placeholder="5000"
              />
            </div>
            <div className="space-y-2">
              <Label>Billing Interval</Label>
              <Select value={interval} onValueChange={setInterval}>
                <option value="monthly">Monthly</option>
                <option value="yearly">Yearly</option>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>Description</Label>
              <Textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Plan description..."
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowDialog(false)}>
              Cancel
            </Button>
            <Button onClick={handleSave} disabled={loading}>
              {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              {editPlan ? "Update" : "Create"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
