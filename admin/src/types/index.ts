export type Profile = {
  id: string;
  full_name: string;
  phone: string;
  email: string | null;
  avatar_url: string | null;
  role: "client" | "worker" | "admin";
  account_status: "active" | "suspended" | "banned" | "deactivated";
  city: string | null;
  state: string | null;
  strikes: number;
  created_at: string;
  updated_at: string;
};

export type WorkerProfile = {
  id: string;
  user_id: string;
  bio: string | null;
  years_of_experience: number | null;
  hourly_rate: number | null;
  verification_status: "unverified" | "pending" | "verified" | "rejected";
  id_document_url: string | null;
  id_document_type: string | null;
  verification_notes: string | null;
  verified_at: string | null;
  verified_by: string | null;
  rating_average: number | null;
  rating_count: number;
  jobs_completed: number;
  created_at: string;
  updated_at: string;
  profiles?: Profile;
  skills?: Skill[];
};

export type Job = {
  id: string;
  client_id: string;
  title: string;
  description: string;
  category_id: string | null;
  budget_min: number | null;
  budget_max: number | null;
  status: "draft" | "open" | "assigned" | "in_progress" | "completed" | "cancelled" | "disputed";
  urgency: "low" | "normal" | "urgent" | "emergency";
  address: string | null;
  city: string | null;
  state: string | null;
  latitude: number | null;
  longitude: number | null;
  scheduled_date: string | null;
  created_at: string;
  updated_at: string;
  profiles?: Profile;
  categories?: Category;
};

export type Booking = {
  id: string;
  job_id: string;
  client_id: string;
  worker_id: string;
  booking_status: "pending" | "accepted" | "in_progress" | "completed" | "cancelled" | "disputed";
  agreed_price: number;
  platform_fee: number;
  worker_payout: number;
  started_at: string | null;
  completed_at: string | null;
  cancelled_at: string | null;
  cancellation_reason: string | null;
  client_rating: number | null;
  client_review: string | null;
  worker_rating: number | null;
  worker_review: string | null;
  created_at: string;
  updated_at: string;
  jobs?: Job;
  client?: Profile;
  worker?: Profile;
};

export type Payment = {
  id: string;
  booking_id: string;
  payer_id: string;
  amount: number;
  platform_fee: number;
  payment_status: "pending" | "processing" | "completed" | "failed" | "refunded";
  payment_method: string | null;
  payment_reference: string | null;
  paid_at: string | null;
  created_at: string;
  updated_at: string;
  bookings?: Booking;
  payer?: Profile;
};

export type Payout = {
  id: string;
  worker_id: string;
  booking_id: string | null;
  amount: number;
  status: "pending" | "processing" | "completed" | "failed";
  bank_name: string | null;
  account_number: string | null;
  account_name: string | null;
  reference: string | null;
  processed_at: string | null;
  processed_by: string | null;
  created_at: string;
  updated_at: string;
  worker?: Profile;
  bookings?: Booking;
};

export type Category = {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  icon: string | null;
  is_active: boolean;
  sort_order: number;
  created_at: string;
  updated_at: string;
};

export type Skill = {
  id: string;
  name: string;
  category_id: string;
  is_active: boolean;
  created_at: string;
  categories?: Category;
};

export type Subscription = {
  id: string;
  user_id: string;
  plan_id: string;
  status: "active" | "cancelled" | "expired" | "past_due";
  current_period_start: string;
  current_period_end: string;
  cancelled_at: string | null;
  created_at: string;
  updated_at: string;
  profiles?: Profile;
  subscription_plans?: SubscriptionPlan;
};

export type SubscriptionPlan = {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  price: number;
  interval: "monthly" | "yearly";
  features: Record<string, unknown> | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
};

export type Report = {
  id: string;
  reporter_id: string;
  reported_id: string;
  booking_id: string | null;
  reason: string;
  description: string | null;
  evidence_urls: string[] | null;
  report_status: "pending" | "reviewing" | "resolved" | "dismissed";
  resolution_notes: string | null;
  resolved_by: string | null;
  resolved_at: string | null;
  created_at: string;
  updated_at: string;
  reporter?: Profile;
  reported?: Profile;
  bookings?: Booking;
};

export type Dispute = {
  id: string;
  booking_id: string;
  raised_by: string;
  reason: string;
  description: string | null;
  evidence_urls: string[] | null;
  dispute_status: "open" | "under_review" | "resolved_client_favor" | "resolved_worker_favor" | "resolved_mutual" | "closed";
  resolution_notes: string | null;
  resolved_by: string | null;
  resolved_at: string | null;
  refund_amount: number | null;
  created_at: string;
  updated_at: string;
  bookings?: Booking;
  raiser?: Profile;
};

export type Notification = {
  id: string;
  user_id: string;
  title: string;
  body: string;
  type: string;
  data: Record<string, unknown> | null;
  read_at: string | null;
  created_at: string;
};

export type AuditLog = {
  id: string;
  actor_id: string;
  action: string;
  entity_type: string;
  entity_id: string;
  old_data: Record<string, unknown> | null;
  new_data: Record<string, unknown> | null;
  ip_address: string | null;
  created_at: string;
  actor?: Profile;
};

export type SystemSetting = {
  id: string;
  key: string;
  value: string;
  description: string | null;
  updated_by: string | null;
  updated_at: string;
};

export type DashboardStats = {
  totalUsers: number;
  activeWorkers: number;
  totalJobs: number;
  totalRevenue: number;
  userGrowth: number;
  workerGrowth: number;
  jobGrowth: number;
  revenueGrowth: number;
};

export type RevenueDataPoint = {
  month: string;
  revenue: number;
  payouts: number;
  profit: number;
};

export type PaginatedResponse<T> = {
  data: T[];
  count: number;
};
