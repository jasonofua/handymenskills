import { createClient } from "@/lib/supabase/server";
import { notFound } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Separator } from "@/components/ui/separator";
import { PageHeader } from "@/components/layout/page-header";
import { formatDate, formatNaira } from "@/lib/format";
import { statusColors, roleColors } from "@/lib/constants";
import { UserActions } from "./user-actions";

interface Props {
  params: Promise<{ id: string }>;
}

export default async function UserDetailPage({ params }: Props) {
  const { id } = await params;
  const supabase = await createClient();

  const { data: user } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", id)
    .single();

  if (!user) notFound();

  const { data: bookings } = await supabase
    .from("bookings")
    .select("id, status, agreed_price, created_at, jobs(title)")
    .or(`client_id.eq.${id},worker_id.eq.${id}`)
    .order("created_at", { ascending: false })
    .limit(10);

  const { data: workerProfile } = user.role === "worker"
    ? await supabase
        .from("worker_profiles")
        .select("*")
        .eq("user_id", id)
        .single()
    : { data: null };

  const initials = user.full_name
    ? user.full_name
        .split(" ")
        .map((n: string) => n[0])
        .join("")
        .toUpperCase()
        .slice(0, 2)
    : "?";

  return (
    <div className="space-y-6">
      <PageHeader title="User Details" />

      <div className="grid gap-6 lg:grid-cols-3">
        <Card className="lg:col-span-1">
          <CardContent className="pt-6">
            <div className="flex flex-col items-center gap-4 text-center">
              <Avatar className="h-20 w-20">
                <AvatarImage src={user.avatar_url || undefined} />
                <AvatarFallback className="text-xl">{initials}</AvatarFallback>
              </Avatar>
              <div>
                <h2 className="text-xl font-bold">{user.full_name}</h2>
                <p className="text-sm text-muted-foreground">{user.email}</p>
              </div>
              <div className="flex gap-2">
                <Badge className={roleColors[user.role] || ""}>{user.role}</Badge>
                <Badge className={statusColors[user.account_status] || ""}>{user.account_status}</Badge>
              </div>
            </div>

            <Separator className="my-6" />

            <div className="space-y-3 text-sm">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Phone</span>
                <span className="font-medium">{user.phone}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">City</span>
                <span className="font-medium">{user.city || "N/A"}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">State</span>
                <span className="font-medium">{user.state || "N/A"}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Strikes</span>
                <span className={`font-medium ${user.strikes > 0 ? "text-destructive" : ""}`}>
                  {user.strikes}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Joined</span>
                <span className="font-medium">{formatDate(user.created_at)}</span>
              </div>
            </div>

            <Separator className="my-6" />

            <UserActions user={user} />
          </CardContent>
        </Card>

        <div className="space-y-6 lg:col-span-2">
          {workerProfile && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Worker Profile</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid gap-4 sm:grid-cols-2">
                  <div>
                    <p className="text-sm text-muted-foreground">Verification</p>
                    <Badge className={statusColors[workerProfile.verification_status] || ""}>
                      {workerProfile.verification_status}
                    </Badge>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Experience</p>
                    <p className="font-medium">{workerProfile.experience_years || 0} years</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Hourly Rate</p>
                    <p className="font-medium">{workerProfile.hourly_rate ? formatNaira(workerProfile.hourly_rate) : "Not set"}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Rating</p>
                    <p className="font-medium">
                      {workerProfile.rating_average
                        ? `${workerProfile.rating_average.toFixed(1)} (${workerProfile.rating_count} reviews)`
                        : "No ratings"}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Jobs Completed</p>
                    <p className="font-medium">{workerProfile.jobs_completed}</p>
                  </div>
                  {workerProfile.bio && (
                    <div className="sm:col-span-2">
                      <p className="text-sm text-muted-foreground">Bio</p>
                      <p className="text-sm">{workerProfile.bio}</p>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          )}

          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Booking History</CardTitle>
            </CardHeader>
            <CardContent>
              {!bookings || bookings.length === 0 ? (
                <p className="text-sm text-muted-foreground">No bookings found.</p>
              ) : (
                <div className="space-y-3">
                  {bookings.map((booking) => {
                    const job = booking.jobs as unknown as { title: string } | null;
                    return (
                      <div key={booking.id} className="flex items-center justify-between rounded-lg border p-3">
                        <div>
                          <p className="text-sm font-medium">{job?.title || "Untitled Job"}</p>
                          <p className="text-xs text-muted-foreground">{formatDate(booking.created_at)}</p>
                        </div>
                        <div className="flex items-center gap-3">
                          <span className="text-sm font-medium">{formatNaira(booking.agreed_price)}</span>
                          <Badge className={statusColors[booking.status] || ""}>
                            {booking.status.replace(/_/g, " ")}
                          </Badge>
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
