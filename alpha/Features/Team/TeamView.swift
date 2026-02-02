//
//  TeamView.swift
//  alpha
//
//  Created by Claude Code on 1/31/26.
//

import SwiftUI
import Combine

// MARK: - Team Member Model

struct TeamMember: Codable, Identifiable {
    let id: String
    let userId: String
    let organizationId: String
    let role: String
    let status: String
    let invitedAt: Date?
    let joinedAt: Date?
    let createdAt: Date
    let updatedAt: Date

    // Populated by backend joins
    let user: User?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case organizationId = "organization_id"
        case role, status
        case invitedAt = "invited_at"
        case joinedAt = "joined_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
    }

    var displayName: String {
        user?.name ?? "Unknown"
    }

    var email: String {
        user?.email ?? ""
    }

    var roleDisplayName: String {
        switch role.uppercased() {
        case "OWNER": return "Owner"
        case "ADMIN": return "Admin"
        case "MEMBER": return "Member"
        case "CONTRACTOR": return "Contractor"
        default: return role.capitalized
        }
    }

    var roleColor: Color {
        switch role.uppercased() {
        case "OWNER": return .purple
        case "ADMIN": return .blue
        case "MEMBER": return .gray
        case "CONTRACTOR": return .orange
        default: return .gray
        }
    }

    var initials: String {
        user?.initials ?? "?"
    }
}

// MARK: - Audit Log Entry Model

struct AuditLogEntry: Codable, Identifiable {
    let id: String
    let organizationId: String
    let userId: String?
    let action: String
    let resourceType: String
    let resourceId: String?
    let metadata: [String: String]?
    let ipAddress: String?
    let createdAt: Date

    // Populated by backend joins
    let user: User?

    enum CodingKeys: String, CodingKey {
        case id
        case organizationId = "organization_id"
        case userId = "user_id"
        case action
        case resourceType = "resource_type"
        case resourceId = "resource_id"
        case metadata
        case ipAddress = "ip_address"
        case createdAt = "created_at"
        case user
    }

    var actionDisplayName: String {
        action.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var userName: String {
        user?.name ?? "System"
    }
}

// MARK: - ViewModel

@MainActor
class TeamViewModel: ObservableObject {
    @Published var members: [TeamMember] = []
    @Published var auditLog: [AuditLogEntry] = []
    @Published var isLoading = false
    @Published var isLoadingAudit = false
    @Published var errorMessage: String?

    private let teamRepository = TeamRepository()

    // Summary stats
    var totalMembers: Int { members.count }
    var adminsCount: Int { members.filter { $0.role.uppercased() == "ADMIN" || $0.role.uppercased() == "OWNER" }.count }
    var contractorsCount: Int { members.filter { $0.role.uppercased() == "CONTRACTOR" }.count }

    func loadMembers() async {
        isLoading = true
        errorMessage = nil

        do {
            members = try await teamRepository.fetchMembers()
        } catch {
            errorMessage = "Failed to load team members: \(error.localizedDescription)"
            members = []
        }

        isLoading = false
    }

    func loadAuditLog() async {
        isLoadingAudit = true

        do {
            auditLog = try await teamRepository.fetchAuditLog()
        } catch {
            print("Failed to load audit log: \(error)")
            auditLog = []
        }

        isLoadingAudit = false
    }

    func removeMember(_ memberId: String) async {
        do {
            try await teamRepository.removeMember(id: memberId)
            await loadMembers()
        } catch {
            errorMessage = "Failed to remove member: \(error.localizedDescription)"
        }
    }

    func updateMemberRole(_ memberId: String, newRole: String) async {
        do {
            _ = try await teamRepository.updateMemberRole(id: memberId, role: newRole)
            await loadMembers()
        } catch {
            errorMessage = "Failed to update role: \(error.localizedDescription)"
        }
    }
}

// MARK: - TeamView

struct TeamView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = TeamViewModel()
    @State private var selectedTab = 0
    @State private var showingInviteSheet = false
    @State private var selectedMember: TeamMember?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("", selection: $selectedTab) {
                    Text("Members").tag(0)
                    if appState.hasCapability(.viewAuditLog) {
                        Text("Activity").tag(1)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                if selectedTab == 0 {
                    membersContent
                } else {
                    auditLogContent
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if appState.hasCapability(.inviteTeamMembers) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showingInviteSheet = true }) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 17, weight: .medium))
                        }
                    }
                }
            }
            .task {
                await viewModel.loadMembers()
            }
            .onChange(of: selectedTab) { _, newValue in
                if newValue == 1 && viewModel.auditLog.isEmpty {
                    Task {
                        await viewModel.loadAuditLog()
                    }
                }
            }
            .sheet(isPresented: $showingInviteSheet) {
                InviteUserSheet(isPresented: $showingInviteSheet, onInvite: {
                    Task {
                        await viewModel.loadMembers()
                    }
                })
                .withAppTheme()
            }
            .sheet(item: $selectedMember) { member in
                MemberDetailSheet(member: member, onUpdate: {
                    Task {
                        await viewModel.loadMembers()
                    }
                })
                .withAppTheme()
            }
        }
    }

    // MARK: - Members Content

    private var membersContent: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.members.isEmpty {
                emptyMembersState
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Summary Cards
                        HStack(spacing: 12) {
                            TeamStatCard(
                                title: "Total",
                                value: "\(viewModel.totalMembers)",
                                icon: "person.3.fill",
                                color: .blue
                            )

                            TeamStatCard(
                                title: "Admins",
                                value: "\(viewModel.adminsCount)",
                                icon: "shield.fill",
                                color: .purple
                            )

                            TeamStatCard(
                                title: "Contractors",
                                value: "\(viewModel.contractorsCount)",
                                icon: "briefcase.fill",
                                color: .orange
                            )
                        }
                        .padding(.horizontal)

                        // Members List
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.members) { member in
                                TeamMemberRow(member: member)
                                    .onTapGesture {
                                        selectedMember = member
                                    }

                                if member.id != viewModel.members.last?.id {
                                    Divider()
                                        .padding(.leading, 76)
                                }
                            }
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    await viewModel.loadMembers()
                }
            }
        }
    }

    // MARK: - Audit Log Content

    private var auditLogContent: some View {
        Group {
            if viewModel.isLoadingAudit {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.auditLog.isEmpty {
                emptyAuditState
            } else {
                List(viewModel.auditLog) { entry in
                    AuditLogRow(entry: entry)
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.loadAuditLog()
                }
            }
        }
    }

    // MARK: - Empty States

    private var emptyMembersState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No team members yet")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Invite people to join your team")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if appState.hasCapability(.inviteTeamMembers) {
                Button(action: { showingInviteSheet = true }) {
                    Text("Invite Members")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }

    private var emptyAuditState: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No activity yet")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Team activity will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Team Stat Card

struct TeamStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Team Member Row

struct TeamMemberRow: View {
    let member: TeamMember

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(member.roleColor.opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay {
                    Text(member.initials)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(member.roleColor)
                }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(member.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)

                Text(member.email)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Role Badge
            Text(member.roleDisplayName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(member.roleColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(member.roleColor.opacity(0.1))
                .cornerRadius(6)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Audit Log Row

struct AuditLogRow: View {
    let entry: AuditLogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.actionDisplayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                Text(entry.createdAt, style: .relative)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 4) {
                Text(entry.userName)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                if let resourceType = entry.resourceType.isEmpty ? nil : entry.resourceType {
                    Text("•")
                        .foregroundColor(.secondary)

                    Text(resourceType.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Invite User Sheet

struct InviteUserSheet: View {
    @Binding var isPresented: Bool
    var onInvite: () -> Void

    @State private var email = ""
    @State private var selectedRole = "MEMBER"
    @State private var isSending = false
    @State private var errorMessage: String?

    private let teamRepository = TeamRepository()

    private let roles = [
        ("ADMIN", "Admin", "Can manage team and billing"),
        ("MEMBER", "Member", "Can access projects and time tracking"),
        ("CONTRACTOR", "Contractor", "Limited access for external collaborators")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email address", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }

                Section("Role") {
                    ForEach(roles, id: \.0) { role in
                        Button(action: { selectedRole = role.0 }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(role.1)
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)

                                    Text(role.2)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if selectedRole == role.0 {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Invite Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .disabled(isSending)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Send Invite") {
                        Task {
                            await sendInvite()
                        }
                    }
                    .disabled(email.isEmpty || isSending)
                }
            }
            .overlay {
                if isSending {
                    ProgressView()
                }
            }
        }
    }

    private func sendInvite() async {
        guard !email.isEmpty else { return }

        isSending = true
        errorMessage = nil

        do {
            try await teamRepository.sendInvite(email: email, role: selectedRole)

            onInvite()
            isPresented = false
        } catch {
            errorMessage = "Failed to send invite: \(error.localizedDescription)"
        }

        isSending = false
    }
}

// MARK: - Member Detail Sheet

struct MemberDetailSheet: View {
    let member: TeamMember
    var onUpdate: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var selectedRole: String
    @State private var showingRemoveConfirmation = false
    @State private var isUpdating = false
    @State private var errorMessage: String?

    private let teamRepository = TeamRepository()

    init(member: TeamMember, onUpdate: @escaping () -> Void) {
        self.member = member
        self.onUpdate = onUpdate
        _selectedRole = State(initialValue: member.role)
    }

    private let roles = ["ADMIN", "MEMBER", "CONTRACTOR"]

    var body: some View {
        NavigationStack {
            Form {
                // Profile Section
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(member.roleColor.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay {
                                Text(member.initials)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(member.roleColor)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(member.displayName)
                                .font(.system(size: 18, weight: .semibold))

                            Text(member.email)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)

                            if let joinedAt = member.joinedAt {
                                Text("Joined \(joinedAt, style: .date)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Role Section
                if member.role.uppercased() != "OWNER" && appState.hasCapability(.assignRoles) {
                    Section("Role") {
                        Picker("Role", selection: $selectedRole) {
                            ForEach(roles, id: \.self) { role in
                                Text(role.capitalized).tag(role)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedRole) { _, newRole in
                            Task {
                                await updateRole(newRole)
                            }
                        }
                    }
                }

                // Remove Section
                if member.role.uppercased() != "OWNER" && appState.hasCapability(.manageUsers) {
                    Section {
                        Button(role: .destructive, action: { showingRemoveConfirmation = true }) {
                            HStack {
                                Spacer()
                                Text("Remove from Team")
                                Spacer()
                            }
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Member Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isUpdating {
                    ProgressView()
                }
            }
            .confirmationDialog(
                "Remove \(member.displayName) from the team?",
                isPresented: $showingRemoveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    Task {
                        await removeMember()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func updateRole(_ newRole: String) async {
        isUpdating = true
        errorMessage = nil

        do {
            _ = try await teamRepository.updateMemberRole(id: member.id, role: newRole)
            onUpdate()
        } catch {
            errorMessage = "Failed to update role: \(error.localizedDescription)"
            selectedRole = member.role // Revert
        }

        isUpdating = false
    }

    private func removeMember() async {
        isUpdating = true
        errorMessage = nil

        do {
            try await teamRepository.removeMember(id: member.id)
            onUpdate()
            dismiss()
        } catch {
            errorMessage = "Failed to remove member: \(error.localizedDescription)"
        }

        isUpdating = false
    }
}

// MARK: - Preview

#Preview("Team View") {
    TeamView()
        .environmentObject({
            let state = AppState()
            state.isAuthenticated = true
            state.currentUser = .preview
            state.organization = .preview
            return state
        }())
}
