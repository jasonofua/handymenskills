"use client";

import { Sidebar } from "@/components/layout/sidebar";
import { Header } from "@/components/layout/header";
import type { Profile } from "@/types";

export function DashboardShell({
  children,
  profile,
  pendingCounts,
}: {
  children: React.ReactNode;
  profile: Profile;
  pendingCounts: Record<string, number>;
}) {
  return (
    <div className="flex h-screen overflow-hidden">
      <Sidebar pendingCounts={pendingCounts} />
      <div className="flex flex-1 flex-col overflow-hidden">
        <Header profile={profile} />
        <main className="flex-1 overflow-y-auto p-6">{children}</main>
      </div>
    </div>
  );
}
