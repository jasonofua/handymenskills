import { createClient } from "@/lib/supabase/server";
import { notFound } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Separator } from "@/components/ui/separator";
import { PageHeader } from "@/components/layout/page-header";
import { formatDate, formatNaira } from "@/lib/format";
import { statusColors } from "@/lib/constants";
import { WorkerVerificationActions } from "./worker-actions";

interface Props {
  params: Promise<{ id: string }>;
}

export default async function WorkerDetailPage({ params }: Props) {
  const { id } = await params;
  const supabase = await createClient();

  const { data: worker } = await supabase
    .from("worker_profiles")
    .select("*, profiles(id, full_name, email, phone, avatar_url, city, state, account_status, created_at)")
    .eq("id", id)
    .single();

  if (!worker) notFound();

  const profile = worker.profiles as {
    id: string;
    full_name: string;
    email: string | null;
    phone: string;
    avatar_url: string | null;
    city: string | null;
    state: string | null;
    account_status: string;
    created_at: string;
  };

  // Get signed URL for ID document if present
  let idDocumentUrl: string | null = null;
  if (worker.id_document_url) {
    const { data: signedData } = await supabase.storage
      .from("id-documents")
      .createSignedUrl(worker.id_document_url, 3600);
    idDocumentUrl = signedData?.signedUrl || null;
  }

  const initials = profile?.full_name
    ? profile.full_name.split(" ").map((n: string) => n[0]).join("").toUpperCase().slice(0, 2)
    : "?";

  return (
    <div className="space-y-6">
      <PageHeader title="Worker Verification Review" />

      <div className="grid gap-6 lg:grid-cols-3">
        <Card className="lg:col-span-1">
          <CardContent className="pt-6">
            <div className="flex flex-col items-center gap-4 text-center">
              <Avatar className="h-20 w-20">
                <AvatarImage src={profile?.avatar_url || undefined} />
                <AvatarFallback className="text-xl">{initials}</AvatarFallback>
              </Avatar>
              <div>
                <h2 className="text-xl font-bold">{profile?.full_name}</h2>
                <p className="text-sm text-muted-foreground">{profile?.email}</p>
              </div>
              <Badge className={statusColors[worker.verification_status] || ""}>
                {worker.verification_status}
              </Badge>
            </div>

            <Separator className="my-6" />

            <div className="space-y-3 text-sm">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Phone</span>
                <span className="font-medium">{profile?.phone}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Location</span>
                <span className="font-medium">
                  {[profile?.city, profile?.state].filter(Boolean).join(", ") || "N/A"}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Experience</span>
                <span className="font-medium">{worker.experience_years || 0} years</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Hourly Rate</span>
                <span className="font-medium">
                  {worker.hourly_rate ? formatNaira(worker.hourly_rate) : "Not set"}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Rating</span>
                <span className="font-medium">
                  {worker.rating_average
                    ? `${worker.rating_average.toFixed(1)} (${worker.rating_count})`
                    : "No ratings"}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Jobs Done</span>
                <span className="font-medium">{worker.jobs_completed}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Joined</span>
                <span className="font-medium">{profile?.created_at ? formatDate(profile.created_at) : "N/A"}</span>
              </div>
            </div>

            {worker.bio && (
              <>
                <Separator className="my-6" />
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Bio</p>
                  <p className="mt-1 text-sm">{worker.bio}</p>
                </div>
              </>
            )}

            {worker.verification_notes && (
              <>
                <Separator className="my-6" />
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Previous Notes</p>
                  <p className="mt-1 text-sm">{worker.verification_notes}</p>
                </div>
              </>
            )}
          </CardContent>
        </Card>

        <div className="space-y-6 lg:col-span-2">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">ID Document</CardTitle>
            </CardHeader>
            <CardContent>
              {worker.id_document_type && (
                <p className="mb-3 text-sm">
                  <span className="text-muted-foreground">Document Type: </span>
                  <span className="font-medium">{worker.id_document_type}</span>
                </p>
              )}
              {idDocumentUrl ? (
                <div className="overflow-hidden rounded-lg border">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={idDocumentUrl}
                    alt="ID Document"
                    className="max-h-[500px] w-full object-contain"
                  />
                </div>
              ) : (
                <div className="flex h-48 items-center justify-center rounded-lg border border-dashed">
                  <p className="text-sm text-muted-foreground">No ID document uploaded</p>
                </div>
              )}
            </CardContent>
          </Card>

          {worker.verification_status === "pending" && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Verification Decision</CardTitle>
              </CardHeader>
              <CardContent>
                <WorkerVerificationActions workerProfileId={worker.id} />
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}
