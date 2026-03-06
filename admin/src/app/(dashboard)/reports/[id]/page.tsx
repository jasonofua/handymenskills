import { createClient } from "@/lib/supabase/server";
import { notFound } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { PageHeader } from "@/components/layout/page-header";
import { formatDate } from "@/lib/format";
import { statusColors } from "@/lib/constants";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { ReportResolutionForm } from "./report-resolution-form";

interface Props {
  params: Promise<{ id: string }>;
}

export default async function ReportDetailPage({ params }: Props) {
  const { id } = await params;
  const supabase = await createClient();

  const { data: report } = await supabase
    .from("reports")
    .select(
      "*, reporter:profiles!reports_reporter_id_fkey(id, full_name, email), reported:profiles!reports_reported_id_fkey(id, full_name, email, strikes, account_status)"
    )
    .eq("id", id)
    .single();

  if (!report) notFound();

  const reporter = report.reporter as { id: string; full_name: string; email: string | null } | null;
  const reported = report.reported as {
    id: string;
    full_name: string;
    email: string | null;
    strikes: number;
    account_status: string;
  } | null;

  const isPending = report.report_status === "pending" || report.report_status === "reviewing";

  return (
    <div className="space-y-6">
      <PageHeader title="Report Details">
        <Link href="/reports">
          <Button variant="outline">Back to Reports</Button>
        </Link>
      </PageHeader>

      <div className="grid gap-6 lg:grid-cols-3">
        <div className="space-y-6 lg:col-span-2">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle className="text-lg">Report</CardTitle>
                <Badge className={statusColors[report.report_status] || ""}>
                  {report.report_status}
                </Badge>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <p className="text-sm font-medium text-muted-foreground">Reason</p>
                <p className="mt-1 font-medium">{report.reason}</p>
              </div>
              {report.description && (
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Description</p>
                  <p className="mt-1 text-sm whitespace-pre-wrap">{report.description}</p>
                </div>
              )}
              {report.evidence_urls && report.evidence_urls.length > 0 && (
                <div>
                  <p className="text-sm font-medium text-muted-foreground">Evidence</p>
                  <div className="mt-2 flex flex-wrap gap-2">
                    {report.evidence_urls.map((url: string, i: number) => (
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
                <p className="text-sm text-muted-foreground">Submitted: {formatDate(report.created_at)}</p>
              </div>

              {report.resolution_notes && (
                <>
                  <Separator />
                  <div>
                    <p className="text-sm font-medium text-muted-foreground">Resolution Notes</p>
                    <p className="mt-1 text-sm">{report.resolution_notes}</p>
                    {report.resolved_at && (
                      <p className="mt-1 text-xs text-muted-foreground">
                        Resolved on {formatDate(report.resolved_at)}
                      </p>
                    )}
                  </div>
                </>
              )}
            </CardContent>
          </Card>

          {isPending && (
            <Card>
              <CardHeader>
                <CardTitle className="text-lg">Resolution</CardTitle>
              </CardHeader>
              <CardContent>
                <ReportResolutionForm reportId={report.id} />
              </CardContent>
            </Card>
          )}
        </div>

        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Reporter</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Name</span>
                <Link href={`/users/${reporter?.id}`} className="font-medium text-primary hover:underline">
                  {reporter?.full_name || "Unknown"}
                </Link>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Email</span>
                <span className="font-medium">{reporter?.email || "N/A"}</span>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-lg">Reported User</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Name</span>
                <Link href={`/users/${reported?.id}`} className="font-medium text-primary hover:underline">
                  {reported?.full_name || "Unknown"}
                </Link>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Email</span>
                <span className="font-medium">{reported?.email || "N/A"}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Status</span>
                <Badge className={statusColors[reported?.account_status || ""] || ""}>
                  {reported?.account_status || "N/A"}
                </Badge>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Strikes</span>
                <span className={`font-bold ${(reported?.strikes || 0) > 0 ? "text-destructive" : ""}`}>
                  {reported?.strikes || 0}/3
                </span>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
