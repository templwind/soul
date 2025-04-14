// Code generated by soul. DO NOT EDIT.

export interface APIUsageStats {
	requestsToday: number;
	requestsThisMonth: number;
	rateLimitRemaining: number;
}

export interface AddonRequest {
	addonID: string;
}

export interface AddonResponse {
	success: boolean;
	message: string;
	addonId: string;
}

export interface AdminUserCommunicationsResponse {
	success: boolean;
	message: string;
	notifications: Notification[];
}

export interface AdminUserRequest {
	userID: string;
}

export interface AdminUserResponse {
	success: boolean;
	message: string;
	user?: User;
}

export interface BlogCategoryRequest {
	categorySlug: string;
	page: number;
	perPage: number;
}

export interface BlogListRequest {
	page: number;
	perPage: number;
	sort: string;
}

export interface BlogPost {
	id: string;
	title: string;
	slug: string;
	content: string;
	status: string;
	authorId: string;
	createdAt: string;
	updatedAt: string;
}

export interface BlogPostRequest {
	slug: string;
}

export interface BlogTagRequest {
	tagSlug: string;
	page: number;
	perPage: number;
}

export interface CheckoutSessionRequest {
	planId: string;
	isYearly: boolean;
}

export interface CheckoutSessionResponse {
	success: boolean;
	message: string;
	sessionId: string;
	url: string;
}

export interface DashboardMetrics {
	totalUsers: number;
	activeUsers: number;
	totalTeams: number;
	activeSubscriptions: number;
}

export interface EmailPreferences {
	marketing: boolean;
	updates: boolean;
	security: boolean;
}

export interface Invitation {
	email: string;
	teamId: string;
	role: string;
	token: string;
	status: string;
	expiresAt: string;
}

export interface InvitationResponse {
	success: boolean;
	message: string;
	invitation?: Invitation;
}

export interface InvitationTokenRequest {
	token: string;
}

export interface InvoiceResponse {
	success: boolean;
	message: string;
	invoices: Struct[];
	id: string;
	amount: number;
	currency: string;
	status: string;
	createdAt: string;
	}:  Json Invoices ;
}

export interface LoginCodeRequest {
	email: string;
}

export interface LoginRequest {
	email: string;
	password: string;
}

export interface Membership {
	userId: string;
	teamId: string;
	role: string;
}

export interface Notification {
	id: string;
	userId: string;
	title: string;
	body: string;
	type: string;
	isRead: boolean;
	createdAt: string;
}

export interface NotificationRequest {
	notificationID: string;
}

export interface NotificationResponse {
	success: boolean;
	message: string;
	notification?: Notification;
}

export interface NotificationsResponse {
	success: boolean;
	message: string;
	notifications: Notification[];
}

export interface Plan {
	id: string;
	name: string;
	priceMonthly: number;
	priceYearly?: number;
	features: Record<string, any>;
}

export interface PortalSessionResponse {
	success: boolean;
	message: string;
	url: string;
}

export interface RegisterRequest {
	name: string;
	email: string;
	password: string;
}

export interface Response {
	success: boolean;
	message: string;
}

export interface SecuritySettings {
	twoFactorEnabled: boolean;
	lastPasswordChange: string;
}

export interface Subscription {
	id: string;
	userId: string;
	planId: string;
	status: string;
	currentPeriodStart: string;
	currentPeriodEnd: string;
}

export interface Team {
	id: string;
	name: string;
	ownerId: string;
}

export interface TeamInvitationRequest {
	teamID: string;
	invitationID: string;
}

export interface TeamInvitationsResponse {
	success: boolean;
	message: string;
	invitations: Invitation[];
}

export interface TeamMemberRequest {
	teamID: string;
	memberID: string;
}

export interface TeamMemberResponse {
	success: boolean;
	message: string;
	member?: Membership;
}

export interface TeamMembersResponse {
	success: boolean;
	message: string;
	members: Membership[];
}

export interface TeamRequest {
	teamID: string;
}

export interface TeamResponse {
	success: boolean;
	message: string;
	team?: Team;
}

export interface User {
	id: string;
	email: string;
	name?: string;
	role?: string;
	apiKey?: string;
	defaultSubdomain: string;
	accountStatus?: string;
	createdAt: string;
	updatedAt: string;
}

export interface VerifyCodeRequest {
	email: string;
	code: string;
}