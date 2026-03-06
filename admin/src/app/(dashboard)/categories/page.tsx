import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/layout/page-header";
import { CategoriesManager } from "./categories-manager";

export default async function CategoriesPage() {
  const supabase = await createClient();

  const { data: categories } = await supabase
    .from("categories")
    .select("*")
    .order("sort_order", { ascending: true });

  const { data: skills } = await supabase
    .from("skills")
    .select("*, categories(name)")
    .order("name", { ascending: true });

  return (
    <div className="space-y-6">
      <PageHeader
        title="Categories & Skills"
        description="Manage service categories and worker skills"
      />
      <CategoriesManager
        initialCategories={categories || []}
        initialSkills={skills || []}
      />
    </div>
  );
}
