"use client";

import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Select } from "@/components/ui/select";
import { useToast } from "@/components/ui/toast";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  createCategory,
  updateCategory,
  deleteCategory,
  createSkill,
  deleteSkill,
} from "./actions";
import type { Category, Skill } from "@/types";
import { Plus, Pencil, Trash2, Loader2 } from "lucide-react";

type SkillWithCategory = Skill & { categories: { name: string } | null };

export function CategoriesManager({
  initialCategories,
  initialSkills,
}: {
  initialCategories: Category[];
  initialSkills: SkillWithCategory[];
}) {
  const [selectedCategory, setSelectedCategory] = useState<Category | null>(null);
  const [showCategoryDialog, setShowCategoryDialog] = useState(false);
  const [showSkillDialog, setShowSkillDialog] = useState(false);
  const [editCategory, setEditCategory] = useState<Category | null>(null);
  const [loading, setLoading] = useState(false);
  const { toast } = useToast();

  // Category form state
  const [catName, setCatName] = useState("");
  const [catSlug, setCatSlug] = useState("");
  const [catDesc, setCatDesc] = useState("");
  const [catIcon, setCatIcon] = useState("");

  // Skill form state
  const [skillName, setSkillName] = useState("");
  const [skillCategoryId, setSkillCategoryId] = useState("");

  const filteredSkills = selectedCategory
    ? initialSkills.filter((s) => s.category_id === selectedCategory.id)
    : initialSkills;

  const openCategoryDialog = (category?: Category) => {
    if (category) {
      setEditCategory(category);
      setCatName(category.name);
      setCatSlug(category.slug);
      setCatDesc(category.description || "");
      setCatIcon(category.icon || "");
    } else {
      setEditCategory(null);
      setCatName("");
      setCatSlug("");
      setCatDesc("");
      setCatIcon("");
    }
    setShowCategoryDialog(true);
  };

  const handleSaveCategory = async () => {
    if (!catName.trim()) {
      toast({ title: "Error", description: "Category name is required.", variant: "destructive" });
      return;
    }
    setLoading(true);
    try {
      const slug = catSlug || catName.toLowerCase().replace(/\s+/g, "-").replace(/[^a-z0-9-]/g, "");
      if (editCategory) {
        const result = await updateCategory(editCategory.id, {
          name: catName,
          slug,
          description: catDesc,
          icon: catIcon,
          is_active: editCategory.is_active,
        });
        if (result.error) {
          toast({ title: "Error", description: result.error, variant: "destructive" });
        } else {
          toast({ title: "Category Updated", variant: "success" });
          setShowCategoryDialog(false);
        }
      } else {
        const result = await createCategory({
          name: catName,
          slug,
          description: catDesc,
          icon: catIcon,
        });
        if (result.error) {
          toast({ title: "Error", description: result.error, variant: "destructive" });
        } else {
          toast({ title: "Category Created", variant: "success" });
          setShowCategoryDialog(false);
        }
      }
    } catch {
      toast({ title: "Error", description: "An unexpected error occurred.", variant: "destructive" });
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteCategory = async (id: string) => {
    if (!confirm("Are you sure you want to delete this category? This will also remove associated skills.")) return;
    setLoading(true);
    try {
      const result = await deleteCategory(id);
      if (result.error) {
        toast({ title: "Error", description: result.error, variant: "destructive" });
      } else {
        toast({ title: "Category Deleted", variant: "success" });
        if (selectedCategory?.id === id) setSelectedCategory(null);
      }
    } catch {
      toast({ title: "Error", description: "An unexpected error occurred.", variant: "destructive" });
    } finally {
      setLoading(false);
    }
  };

  const handleAddSkill = async () => {
    if (!skillName.trim() || !skillCategoryId) {
      toast({ title: "Error", description: "Skill name and category are required.", variant: "destructive" });
      return;
    }
    setLoading(true);
    try {
      const result = await createSkill({ name: skillName, category_id: skillCategoryId });
      if (result.error) {
        toast({ title: "Error", description: result.error, variant: "destructive" });
      } else {
        toast({ title: "Skill Created", variant: "success" });
        setShowSkillDialog(false);
        setSkillName("");
      }
    } catch {
      toast({ title: "Error", description: "An unexpected error occurred.", variant: "destructive" });
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteSkill = async (id: string) => {
    if (!confirm("Are you sure you want to delete this skill?")) return;
    try {
      const result = await deleteSkill(id);
      if (result.error) {
        toast({ title: "Error", description: result.error, variant: "destructive" });
      } else {
        toast({ title: "Skill Deleted", variant: "success" });
      }
    } catch {
      toast({ title: "Error", description: "An unexpected error occurred.", variant: "destructive" });
    }
  };

  return (
    <div className="grid gap-6 lg:grid-cols-2">
      {/* Categories Panel */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="text-lg">Categories</CardTitle>
          <Button size="sm" onClick={() => openCategoryDialog()}>
            <Plus className="mr-2 h-4 w-4" />
            Add Category
          </Button>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            {initialCategories.length === 0 ? (
              <p className="text-sm text-muted-foreground">No categories yet.</p>
            ) : (
              initialCategories.map((category) => (
                <div
                  key={category.id}
                  className={`flex items-center justify-between rounded-lg border p-3 cursor-pointer transition-colors ${
                    selectedCategory?.id === category.id ? "bg-accent" : "hover:bg-muted/50"
                  }`}
                  onClick={() => setSelectedCategory(category)}
                >
                  <div className="flex items-center gap-3">
                    <div>
                      <p className="font-medium">{category.name}</p>
                      {category.description && (
                        <p className="text-xs text-muted-foreground">{category.description}</p>
                      )}
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant={category.is_active ? "success" : "secondary"}>
                      {category.is_active ? "Active" : "Inactive"}
                    </Badge>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8"
                      onClick={(e) => {
                        e.stopPropagation();
                        openCategoryDialog(category);
                      }}
                    >
                      <Pencil className="h-3.5 w-3.5" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8 text-destructive"
                      onClick={(e) => {
                        e.stopPropagation();
                        handleDeleteCategory(category.id);
                      }}
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </Button>
                  </div>
                </div>
              ))
            )}
          </div>
        </CardContent>
      </Card>

      {/* Skills Panel */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="text-lg">
            Skills {selectedCategory ? `- ${selectedCategory.name}` : ""}
          </CardTitle>
          <Button
            size="sm"
            onClick={() => {
              setSkillCategoryId(selectedCategory?.id || "");
              setSkillName("");
              setShowSkillDialog(true);
            }}
          >
            <Plus className="mr-2 h-4 w-4" />
            Add Skill
          </Button>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            {filteredSkills.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                {selectedCategory ? "No skills in this category." : "No skills yet."}
              </p>
            ) : (
              filteredSkills.map((skill) => (
                <div
                  key={skill.id}
                  className="flex items-center justify-between rounded-lg border p-3"
                >
                  <div>
                    <p className="font-medium">{skill.name}</p>
                    <p className="text-xs text-muted-foreground">
                      {skill.categories?.name || ""}
                    </p>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant={skill.is_active ? "success" : "secondary"}>
                      {skill.is_active ? "Active" : "Inactive"}
                    </Badge>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8 text-destructive"
                      onClick={() => handleDeleteSkill(skill.id)}
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </Button>
                  </div>
                </div>
              ))
            )}
          </div>
        </CardContent>
      </Card>

      {/* Category Dialog */}
      <Dialog open={showCategoryDialog} onOpenChange={setShowCategoryDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editCategory ? "Edit Category" : "New Category"}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Name</Label>
              <Input value={catName} onChange={(e) => setCatName(e.target.value)} placeholder="e.g. Plumbing" />
            </div>
            <div className="space-y-2">
              <Label>Slug</Label>
              <Input
                value={catSlug}
                onChange={(e) => setCatSlug(e.target.value)}
                placeholder="auto-generated from name"
              />
            </div>
            <div className="space-y-2">
              <Label>Description</Label>
              <Input value={catDesc} onChange={(e) => setCatDesc(e.target.value)} placeholder="Optional description" />
            </div>
            <div className="space-y-2">
              <Label>Icon</Label>
              <Input value={catIcon} onChange={(e) => setCatIcon(e.target.value)} placeholder="Icon name (e.g. wrench)" />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowCategoryDialog(false)}>
              Cancel
            </Button>
            <Button onClick={handleSaveCategory} disabled={loading}>
              {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              {editCategory ? "Update" : "Create"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Skill Dialog */}
      <Dialog open={showSkillDialog} onOpenChange={setShowSkillDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>New Skill</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label>Skill Name</Label>
              <Input
                value={skillName}
                onChange={(e) => setSkillName(e.target.value)}
                placeholder="e.g. Pipe Fitting"
              />
            </div>
            <div className="space-y-2">
              <Label>Category</Label>
              <Select
                value={skillCategoryId}
                onValueChange={setSkillCategoryId}
              >
                <option value="">Select category...</option>
                {initialCategories.map((cat) => (
                  <option key={cat.id} value={cat.id}>
                    {cat.name}
                  </option>
                ))}
              </Select>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowSkillDialog(false)}>
              Cancel
            </Button>
            <Button onClick={handleAddSkill} disabled={loading}>
              {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              Create Skill
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
