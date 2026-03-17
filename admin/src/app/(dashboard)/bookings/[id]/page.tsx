import { createClient } from "@/lib/supabase/server";
import { notFound } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { PageHeader } from "@/components/layout/page-header";
import { formatDate, formatDateTime, formatNaira } from "@/lib/format";
import { statusColors } from "@/lib/constants";
import Link from "next/link";
import { Button } from "@/components/ui/button";

interface Props {
  params: Promise<{ id: string }>;
}

export default async function BookingDetailPage({ params }: Props) {
  const { id } = await params;
  const supabase = await createClient();

  const { data: booking } = await supabase
    .from("bookings")
    .select(
      "*, jobs(id, title), client:profiles!bookings_client_id_fkey(id, full_name, email, phone), worker:profiles!bookings_worker_id_fkey(id, full_name, email, phone)"
    )
    .eq("id", id)
    .single();

  if (!booking) notFound();

  const job = booking.jobs as { id: string; title: string } | null;
  const client = booking.client as { id: string; full_name: string; email: string | null; phone: string } | null;
  const worker = booking.worker as { id: string; full_name: string; email: string | null; phone: string } | null;

  const { data: payments } = await supabase
    .from("payments")
    .select("*")
    .eq("booking_id", id)
    .order("created_at", { ascending: false });

  const { data: reviews } = await supabase
    .from("reviews")
    .select("*, reviewer:profiles!reviews_reviewer_id_fkey(full_name), reviewee:profiles!reviews_reviewee_id_fkey(full_name)")
    .eq("booking_id", id)
    .order("created_at", { ascending: false });

  const timelineEvents = [
    { label: "Booking Created", date: booking.created_at, active: true },
    { label: "Started", date: booking.started_at, active: !!booking.started_at },
    { label: "Completed", date: booking.completed_at, active: !!booking.completed_at },
    ...(booking.cancelled_at
      ? [{ label: "Cancelled", date: booking.cancelled_at, active: true }]
      : []),
  ];

  return (
    <div className="space-y-6">
      <PageHeader title="Booking Details">
        <Link href="/bookings">
          <Button variant="outline">Back to Bookings</Button>
        </Link>
      </PageHeader>

      <div className="grid gap-6 lg:grid-cols-3">
        <div className="space-y-6 lg:col-span-2">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle className="text-lg">
                  {job?.title || "Untitled Job"}
                </CardTitle>
                <Badge className={statusColors[booking.status] || ""}>
                  {booking.status.replace(/_/g, " ")}
                </Badge>
              </div>
            </CardHeader>
            <CardContent>
              <div className="grid gap-4 sm:grid-cols-2">
                <div>
                  <p className="text-sm text-muted-foreground">Client</p>
                  <Link href={`/users/${client?.id}`} className="font-medium text-primary hover:underline">
                    {client?.full_name || "Unknown"}
                  </Link>
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Worker</p>
                  <Link href={`/users/${worker?.id}`} className="font-medium text-primary hover:underline">
                    {worker?.full_name || "Unknown"}
                  </Link>
                </div>
              </div>

              {booking.cancellation_reason && (
                <>
                  <Separator className="my-4" />
                  <div>
                    <p className="text-sm font-medium text-destructive">Cancellation Reason</p>
                    <p className="mt-1 text-sm">{booking.cancellation_reason}</p>
                  </div>
                </>
              )}

              {reviews && reviews.length > 0 && (
                <>
                  <Separator className="my-4" />
                  <p className="mb-3 text-sm font-medium">Reviews</p>
                  <div className="grid gap-4 sm:grid-cols-2">
                    {reviews.map((review: Record<string, unknown>) => {
                      const reviewer = review.reviewer as { full_name: string } | null;
                      const reviewee = review.reviewee as { full_name: string } | null;
                      return (
                        <div key={review.id as string} className="rounded-lg border p-3">
                          <div className="flex items-center justify-between">
                            <p className="text-sm font-medium">{reviewer?.full_name || "Unknown"}</p>
                            <div className="flex items-center gap-1">
                              <span className="text-sm font-bold text-amber-500">{"★".repeat(review.overall_rating as number)}</span>
                              <span className="text-sm text-muted-foreground">{"★".repeat(5 - (review.overall_rating as number))}</span>
                            </div>
                          </div>
                          <p className="mt-0.5 text-xs text-muted-foreground">
                            Reviewed {reviewee?.full_name || "Unknown"}
                          </p>
                          {review.comment ? (
                            <p className="mt-2 text-sm">{String(review.comment)}</p>
                          ) : null}
                          {(review.quality_rating || review.communication_rating || review.punctuality_rating || review.value_rating) ? (
                            <div className="mt-2 flex flex-wrap gap-2 text-xs text-muted-foreground">
                              {review.quality_rating ? <span>Quality: {String(review.quality_rating)}/5</span> : null}
                              {review.communication_rating ? <span>Communication: {String(review.communication_rating)}/5</span> : null}
                              {review.punctuality_rating ? <span>Punctuality: {String(review.punctuality_rating)}/5</span> : null}
                              {review.value_rating ? <span>Value: {String(review.value_rating)}/5</span> : null}
                            </div>
                          ) : null}
                        </div>
                      );
                    })}
                  </div>
                </>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Payments</CardTitle>
            </CardHeader>
            <CardContent>
              {!payments || payments.length === 0 ? (
                <p className="text-sm text-muted-foreground">No payments recorded.</p>
              ) : (
                <div className="space-y-3">
                  {payments.map((payment) => (
                    <div key={payment.id} className="flex items-center justify-between rounded-lg border p-3">
                      <div>
                        <p className="text-sm font-medium">{formatNaira(payment.amount)}</p>
                        <p className="text-xs text-muted-foreground">
                          Ref: {payment.paystack_reference || "N/A"}
                        </p>
                      </div>
                      <div className="text-right">
                        <Badge className={statusColors[payment.status] || ""}>
                          {payment.status}
                        </Badge>
                        <p className="mt-1 text-xs text-muted-foreground">
                          {payment.created_at ? formatDate(payment.created_at) : "Unpaid"}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Financial Breakdown</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3 text-sm">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Agreed Price</span>
                  <span className="font-bold">{formatNaira(booking.agreed_price)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Platform Fee (15%)</span>
                  <span className="font-medium">{formatNaira(booking.platform_commission)}</span>
                </div>
                <Separator />
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Worker Payout</span>
                  <span className="font-bold text-emerald-600">{formatNaira(booking.worker_payout)}</span>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Timeline</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {timelineEvents.map((event, i) => (
                  <div key={i} className="flex items-start gap-3">
                    <div
                      className={`mt-1 h-2.5 w-2.5 rounded-full ${
                        event.active ? "bg-primary" : "bg-muted"
                      }`}
                    />
                    <div>
                      <p className={`text-sm font-medium ${!event.active ? "text-muted-foreground" : ""}`}>
                        {event.label}
                      </p>
                      {event.date && (
                        <p className="text-xs text-muted-foreground">
                          {formatDateTime(event.date)}
                        </p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
