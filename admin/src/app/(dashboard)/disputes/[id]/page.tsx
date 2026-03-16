import { createClient } from "@/lib/supabase/server";
import { notFound } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { PageHeader } from "@/components/layout/page-header";
import { formatDate, formatNaira } from "@/lib/format";
import { statusColors } from "@/lib/constants";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { DisputeResolutionForm } from "./dispute-resolution-form";

interface Props {
  params: Promise<{ id: string }>;
}

export default async function DisputeDetailPage({ params }: Props) {
  const { id } = await params;
  const supabase = await createClient();

  const { data: dispute } = await supabase
    .from("disputes")
    .select(
      "*, raiser:profiles!disputes_initiator_id_fkey(id, full_name, email), bookings(id, agreed_price, platform_commission, worker_payout, status, client:profiles!bookings_client_id_fkey(id, full_name), worker:profiles!bookings_worker_id_fkey(id, full_name), jobs(title))"
    )
    .eq("id", id)
    .single();

  if (!dispute) notFound();

  const raiser = dispute.raiser as { id: string; full_name: string; email: string | null } | null;
  const booking = dispute.bookings as {
    id: string;
    agreed_price: number;
    platform_commission: number;
    worker_payout: number;
    status: string;
    client: { id: string; full_name: string } | null;
    worker: { id: string; full_name: string } | null;
    jobs: { title: string } | null;
  } | null;

  const isOpen = dispute.status === "open" || dispute.status === "under_review";

  return (
    <div className="space-y-6">
      <PageHeader title="Dispute Details">
        <Link href="/disputes">
          <Button variant="outline">Back to Disputes</Button>
        </Link>
      </PageHeader>

      <div className="grid gap-6 lg:grid-cols-3">
        <div className="space-y-6 lg:col-span-2">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle className="text-lg">Dispute</CardTitle>
                <Badge className={statusColors[dispute.status] || ""}>
                  {dispute.status.replace(/_/g, " ")}
                </Badge>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Reason</p>
                <p className="mt-1 font-medium">{dispute.reason}</p>
              </div>
              {dispute.description && (
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Description</p>
                  <p className="mt-1 text-sm whitespace-pre-wrap">{dispute.description}</p>
                </div>
              )}
              {dispute.evidence_urls && dispute.evidence_urls.length > 0 && (
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Evidence</p>
                  <div className="mt-2 flex flex-wrap gap-2">
                    {dispute.evidence_urls.map((url: string, i: number) => (
                      <a
                        key={i}
                        href={url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-sm text-primary hover:underline"
                      >
                        Evidence {i + 1}
                      </a>
                    ))}
                  </div>
                </div>
              )}
              <div>
                <p className="text-sm text-muted-foreground">
                  Raised on {formatDate(dispute.created_at)}
                </p>
              </div>

              {dispute.resolution_notes && (
                <>
                  <Separator />
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Resolution Notes</p>
                    <p className="mt-1 text-sm">{dispute.resolution_notes}</p>
                    {dispute.refund_amount && (
                      <p className="mt-1 text-sm font-medium">
                        Refund: {formatNaira(dispute.refund_amount)}
                      </p>
                    )}
                    {dispute.resolved_at && (
                      <p className="mt-1 text-xs text-muted-foreground">
                        Resolved on {formatDate(dispute.resolved_at)}
                      </p>
                    )}
                  </div>
                </>
              )}
            </CardContent>
          </Card>

          {isOpen && booking && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Resolution</CardTitle>
              </CardHeader>
              <CardContent>
                <DisputeResolutionForm
                  disputeId={dispute.id}
                  agreedPrice={booking.agreed_price}
                />
              </CardContent>
            </Card>
          )}
        </div>

        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Booking</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Job</span>
                <span className="font-medium">{booking?.jobs?.title || "N/A"}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Client</span>
                <Link
                  href={`/users/${booking?.client?.id}`}
                  className="font-medium text-primary hover:underline"
                >
                  {booking?.client?.full_name || "Unknown"}
                </Link>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Worker</span>
                <Link
                  href={`/users/${booking?.worker?.id}`}
                  className="font-medium text-primary hover:underline"
                >
                  {booking?.worker?.full_name || "Unknown"}
                </Link>
              </div>
              <Separator className="my-2" />
              <div className="flex justify-between">
                <span className="text-muted-foreground">Agreed Price</span>
                <span className="font-bold">{formatNaira(booking?.agreed_price || 0)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Platform Fee</span>
                <span>{formatNaira(booking?.platform_commission || 0)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Worker Payout</span>
                <span>{formatNaira(booking?.worker_payout || 0)}</span>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Raised By</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Name</span>
                <Link href={`/users/${raiser?.id}`} className="font-medium text-primary hover:underline">
                  {raiser?.full_name || "Unknown"}
                </Link>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Email</span>
                <span className="font-medium">{raiser?.email || "N/A"}</span>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
