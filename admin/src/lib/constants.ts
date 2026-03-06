import {
  LayoutDashboard,
  Users,
  ShieldCheck,
  Briefcase,
  Calendar,
  Wallet,
  CreditCard,
  TrendingUp,
  Flag,
  Scale,
  FolderTree,
  Crown,
  Settings,
  ScrollText,
  type LucideIcon,
} from "lucide-react";

export type NavItem = {
  title: string;
  href: string;
  icon: LucideIcon;
  badge?: string;
  children?: { title: string; href: string }[];
};

export const navItems: NavItem[] = [
  { title: "Dashboard", href: "/", icon: LayoutDashboard },
  { title: "Users", href: "/users", icon: Users },
  { title: "Worker Verification", href: "/workers", icon: ShieldCheck },
  { title: "Jobs", href: "/jobs", icon: Briefcase },
  { title: "Bookings", href: "/bookings", icon: Calendar },
  {
    title: "Finance",
    href: "/finance",
    icon: Wallet,
    children: [
      { title: "Payments", href: "/finance" },
      { title: "Payouts", href: "/finance/payouts" },
      { title: "Revenue", href: "/finance/revenue" },
    ],
  },
  { title: "Reports", href: "/reports", icon: Flag },
  { title: "Disputes", href: "/disputes", icon: Scale },
  { title: "Categories", href: "/categories", icon: FolderTree },
  { title: "Subscriptions", href: "/subscriptions", icon: Crown },
  { title: "Settings", href: "/settings", icon: Settings },
  { title: "Audit Logs", href: "/audit-logs", icon: ScrollText },
];

export const statusColors: Record<string, string> = {
  // Account status
  active: "bg-emerald-100 text-emerald-800",
  suspended: "bg-amber-100 text-amber-800",
  banned: "bg-red-100 text-red-800",
  deactivated: "bg-gray-100 text-gray-800",

  // Verification status
  unverified: "bg-gray-100 text-gray-800",
  pending: "bg-amber-100 text-amber-800",
  verified: "bg-emerald-100 text-emerald-800",
  rejected: "bg-red-100 text-red-800",

  // Job status
  draft: "bg-gray-100 text-gray-800",
  open: "bg-blue-100 text-blue-800",
  assigned: "bg-indigo-100 text-indigo-800",
  in_progress: "bg-amber-100 text-amber-800",
  completed: "bg-emerald-100 text-emerald-800",
  cancelled: "bg-red-100 text-red-800",
  disputed: "bg-orange-100 text-orange-800",

  // Booking status
  accepted: "bg-blue-100 text-blue-800",

  // Payment status
  processing: "bg-amber-100 text-amber-800",
  failed: "bg-red-100 text-red-800",
  refunded: "bg-purple-100 text-purple-800",

  // Report status
  reviewing: "bg-blue-100 text-blue-800",
  resolved: "bg-emerald-100 text-emerald-800",
  dismissed: "bg-gray-100 text-gray-800",

  // Dispute status
  under_review: "bg-blue-100 text-blue-800",
  resolved_client_favor: "bg-emerald-100 text-emerald-800",
  resolved_worker_favor: "bg-emerald-100 text-emerald-800",
  resolved_mutual: "bg-teal-100 text-teal-800",
  closed: "bg-gray-100 text-gray-800",

  // Subscription status
  expired: "bg-red-100 text-red-800",
  past_due: "bg-orange-100 text-orange-800",
};

export const roleColors: Record<string, string> = {
  admin: "bg-purple-100 text-purple-800",
  client: "bg-blue-100 text-blue-800",
  worker: "bg-emerald-100 text-emerald-800",
};

export const urgencyColors: Record<string, string> = {
  low: "bg-gray-100 text-gray-800",
  normal: "bg-blue-100 text-blue-800",
  urgent: "bg-amber-100 text-amber-800",
  emergency: "bg-red-100 text-red-800",
};

export const PLATFORM_COMMISSION = 0.15;
export const CURRENCY_SYMBOL = "\u20A6";
export const DEFAULT_PAGE_SIZE = 20;
