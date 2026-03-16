import { createClient } from "@/lib/supabase/server";
import { notFound } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { PageHeader } from "@/components/layout/page-header";
import { formatDate, formatNaira, formatDateTime } from "@/lib/format";
import { statusColors, urgencyColors } from "@/lib/constants";
import Link from "next/link";
import { Button } from "@/components/ui/button";

interface Props {
  params: Promise<{ id: string }>;
}

export default async function JobDetailPage({ params }: Props) {
  const { id } = await params;
  const supabase = await createClient();

  const { data: job } = await supabase
    .from("jobs")
    .select("*, profiles!jobs_client_id_fkey(id, full_name, email, phone), categories(name)")
    .eq("id", id)
    .single();

  if (!job) notFound();

  const client = job.profiles as { id: string; full_name: string; email: string | null; phone: string } | null;
  const category = job.categories as { name: string } | null;

  const { data: bookings } = await supabase
    .from("bookings")
    .select("*, worker:profiles!bookings_worker_id_fkey(id, full_name)")
    .eq("job_id", id)
    .order("created_at", { ascending: false });

  return (
    <div className="space-y-6">
      <PageHeader title="Job Details">
        <Link href="/jobs">
          <Button variant="outline">Back to Jobs</Button>
        </Link>
      </PageHeader>

      <div className="grid gap-6 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader>
            <div className="flex items-start justify-between">
              <div>
                <CardTitle>{job.title}</CardTitle>
              </div>
              <div className="flex gap-2">
                <Badge className={statusColors[job.job_status] || ""}>
                  {job.job_status.replace(/_/g, " ")}
                </Badge>
                <Badge className={urgencyColors[job.urgency] || ""}>
                  {job.urgency}
                </Badge>
              </div>
            </div>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Description</p>
              <p className="mt-1 text-sm whitespace-pre-wrap">{job.description}</p>
            </div>

            <Separator />

            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <p className="text-sm text-muted-foreground">Category</p>
                <p className="font-medium">{category?.name || "Uncategorized"}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Budget</p>
                <p className="font-medium">
                  {job.budget_min && job.budget_max
                    ? `${formatNaira(job.budget_min)} - ${formatNaira(job.budget_max)}`
                    : job.budget_min
                    ? formatNaira(job.budget_min)
                    : "Not specified"}
                </p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Location</p>
                <p className="font-medium">
                  {[job.address, job.city, job.state].filter(Boolean).join(", ") || "Not specified"}
                </p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Scheduled Date</p>
                <p className="font-medium">
                  {job.scheduled_date ? formatDateTime(job.scheduled_date) : "Flexible"}
                </p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Posted</p>
                <p className="font-medium">{formatDate(job.created_at)}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Last Updated</p>
                <p className="font-medium">{formatDate(job.updated_at)}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Client</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Name</span>
                  <Link href={`/users/${client?.id}`} className="font-medium text-primary hover:underline">
                    {client?.full_name || "Unknown"}
                  </Link>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Email</span>
                  <span className="font-medium">{client?.email || "N/A"}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Phone</span>
                  <span className="font-medium">{client?.phone || "N/A"}</span>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Bookings ({bookings?.length || 0})</CardTitle>
            </CardHeader>
            <CardContent>
              {!bookings || bookings.length === 0 ? (
                <p className="text-sm text-muted-foreground">No bookings for this job.</p>
              ) : (
                <div className="space-y-3">
                  {bookings.map((booking) => {
                    const worker = booking.worker as { id: string; full_name: string } | null;
                    return (
                      <div key={booking.id} className="rounded-lg border p-3">
                        <div className="flex items-center justify-between">
                          <Link href={`/users/${worker?.id}`} className="text-sm font-medium hover:underline">
                            {worker?.full_name || "Unknown"}
                          </Link>
                          <Badge className={statusColors[booking.status] || ""}>
                            {booking.status.replace(/_/g, " ")}
                          </Badge>
                        </div>
                        <div className="mt-1 flex items-center justify-between text-xs text-muted-foreground">
                          <span>{formatNaira(booking.agreed_price)}</span>
                          <Link href={`/bookings/${booking.id}`} className="text-primary hover:underline">
                            View booking
                          </Link>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
