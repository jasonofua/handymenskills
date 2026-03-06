"use client";

import React, { useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import { navItems, type NavItem } from "@/lib/constants";
import { ChevronDown, ChevronLeft, ChevronRight } from "lucide-react";
import { Button } from "@/components/ui/button";

function NavItemComponent({
  item,
  collapsed,
  pendingCounts,
}: {
  item: NavItem;
  collapsed: boolean;
  pendingCounts?: Record<string, number>;
}) {
  const pathname = usePathname();
  const [childOpen, setChildOpen] = useState(false);

  const isActive =
    item.href === "/"
      ? pathname === "/"
      : pathname.startsWith(item.href);

  const Icon = item.icon;
  const badgeCount = pendingCounts?.[item.href] || 0;

  if (item.children) {
    return (
      <div>
        <button
          onClick={() => setChildOpen(!childOpen)}
          className={cn(
            "flex w-full items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground",
            isActive && "bg-accent text-accent-foreground"
          )}
        >
          <Icon className="h-4 w-4 shrink-0" />
          {!collapsed && (
            <>
              <span className="flex-1 text-left">{item.title}</span>
              <ChevronDown
                className={cn(
                  "h-4 w-4 shrink-0 transition-transform",
                  childOpen && "rotate-180"
                )}
              />
            </>
          )}
        </button>
        {childOpen && !collapsed && (
          <div className="ml-4 mt-1 space-y-1 border-l pl-3">
            {item.children.map((child) => {
              const childActive = pathname === child.href;
              return (
                <Link
                  key={child.href}
                  href={child.href}
                  className={cn(
                    "block rounded-lg px-3 py-1.5 text-sm transition-colors hover:bg-accent",
                    childActive && "bg-accent font-medium"
                  )}
                >
                  {child.title}
                </Link>
              );
            })}
          </div>
        )}
      </div>
    );
  }

  return (
    <Link
      href={item.href}
      className={cn(
        "flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground",
        isActive && "bg-accent text-accent-foreground"
      )}
    >
      <Icon className="h-4 w-4 shrink-0" />
      {!collapsed && (
        <>
          <span className="flex-1">{item.title}</span>
          {badgeCount > 0 && (
            <span className="flex h-5 min-w-5 items-center justify-center rounded-full bg-destructive px-1.5 text-[10px] font-bold text-white">
              {badgeCount}
            </span>
          )}
        </>
      )}
    </Link>
  );
}

export function Sidebar({
  pendingCounts,
}: {
  pendingCounts?: Record<string, number>;
}) {
  const [collapsed, setCollapsed] = useState(false);

  return (
    <aside
      className={cn(
        "flex h-screen flex-col border-r bg-sidebar text-sidebar-foreground transition-all duration-300",
        collapsed ? "w-16" : "w-64"
      )}
    >
      <div className="flex h-14 items-center border-b px-3">
        {!collapsed && (
          <Link href="/" className="flex items-center gap-2 font-bold">
            <span className="text-lg">Artisan</span>
            <span className="text-xs font-normal text-muted-foreground">Admin</span>
          </Link>
        )}
        <Button
          variant="ghost"
          size="icon"
          className={cn("ml-auto h-8 w-8", collapsed && "mx-auto")}
          onClick={() => setCollapsed(!collapsed)}
        >
          {collapsed ? (
            <ChevronRight className="h-4 w-4" />
          ) : (
            <ChevronLeft className="h-4 w-4" />
          )}
        </Button>
      </div>

      <nav className="flex-1 space-y-1 overflow-y-auto p-3">
        {navItems.map((item) => (
          <NavItemComponent
            key={item.href}
            item={item}
            collapsed={collapsed}
            pendingCounts={pendingCounts}
          />
        ))}
      </nav>

      <div className="border-t p-3">
        {!collapsed && (
          <p className="text-xs text-muted-foreground">
            Artisan Marketplace v1.0
          </p>
        )}
      </div>
    </aside>
  );
}
