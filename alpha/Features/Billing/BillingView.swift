//
//  BillingView.swift
//  alpha
//
//  Created by Claude Code on 12/16/25.
//

import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
class BillingViewModel: ObservableObject {
    @Published var invoices: [Invoice] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFilter: InvoiceFilter = .outstanding

    // Summary metrics
    @Published var outstandingCount: Int = 0
    @Published var outstandingTotal: Double = 0
    @Published var draftCount: Int = 0
    @Published var paidThisMonth: Double = 0

    private let invoiceRepository = InvoiceRepository()

    var filteredInvoices: [Invoice] {
        switch selectedFilter {
        case .outstanding:
            return invoices.filter { $0.status == .sent || $0.status == .overdue }
        case .all:
            return invoices
        case .drafts:
            return invoices.filter { $0.status == .draft }
        case .paid:
            return invoices.filter { $0.status == .paid }
        }
    }

    // MARK: - Public Methods

    func loadInvoices() async {
        isLoading = true
        errorMessage = nil

        do {
            invoices = try await invoiceRepository.fetchInvoices()
            calculateSummaries()
        } catch {
            print("Failed to load invoices: \(error)")
            errorMessage = "Failed to load invoices"
            invoices = []
        }

        isLoading = false
    }

    func markAsPaid(_ invoiceId: String) async {
        do {
            _ = try await invoiceRepository.markAsPaid(id: invoiceId)
            await loadInvoices()
        } catch {
            errorMessage = "Failed to update invoice: \(error.localizedDescription)"
        }
    }

    func sendInvoice(_ invoiceId: String) async {
        do {
            _ = try await invoiceRepository.sendInvoice(id: invoiceId)
            await loadInvoices()
        } catch {
            errorMessage = "Failed to send invoice: \(error.localizedDescription)"
        }
    }

    // MARK: - Private Methods

    private func calculateSummaries() {
        let outstanding = invoices.filter { $0.status == .sent || $0.status == .overdue }
        outstandingCount = outstanding.count
        outstandingTotal = outstanding.reduce(0) { $0 + $1.total }

        draftCount = invoices.filter { $0.status == .draft }.count

        // Calculate paid this month
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let paidInvoices = invoices.filter { invoice in
            guard invoice.status == .paid, let paidAt = invoice.paidAt else { return false }
            return paidAt >= startOfMonth
        }
        paidThisMonth = paidInvoices.reduce(0) { $0 + $1.total }
    }
}

enum InvoiceFilter: String, CaseIterable, Identifiable {
    case outstanding = "Outstanding"
    case all = "All"
    case drafts = "Drafts"
    case paid = "Paid"

    var id: String { rawValue }
}

// MARK: - BillingView

struct BillingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = BillingViewModel()
    @State private var selectedTab = 0
    @State private var selectedInvoice: Invoice?
    @State private var showingCreateInvoice = false
    @State private var showingBillingRules = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker - only show if user has expense capabilities
                if appState.hasCapability(.submitExpenses) || appState.hasCapability(.approveExpenses) {
                    Picker("", selection: $selectedTab) {
                        Text("Invoices").tag(0)
                        Text("Expenses").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                }

                // Content
                if selectedTab == 0 {
                    invoicesContent
                } else {
                    ExpenseViewContent()
                }
            }
            .background(Color.alphaGroupedBackground)
            .navigationTitle("Billing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if appState.hasCapability(.configureBillingRules) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(action: { showingBillingRules = true }) {
                                Label("Billing Rules", systemImage: "gearshape")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 17, weight: .medium))
                        }
                    }
                }
            }
            .sheet(item: $selectedInvoice) { invoice in
                InvoiceDetailSheet(invoice: invoice, onUpdate: {
                    Task {
                        await viewModel.loadInvoices()
                    }
                })
            }
            .sheet(isPresented: $showingCreateInvoice) {
                CreateInvoiceSheet(isPresented: $showingCreateInvoice)
            }
            .sheet(isPresented: $showingBillingRules) {
                BillingRulesSheet(isPresented: $showingBillingRules)
            }
        }
    }

    // MARK: - Invoices Content

    private var invoicesContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary Cards
                HStack(spacing: 12) {
                    BillingSummaryCard(
                        title: "Outstanding",
                        count: viewModel.outstandingCount,
                        total: viewModel.outstandingTotal,
                        icon: "doc.text",
                        color: .orange
                    )

                    BillingSummaryCard(
                        title: "Paid This Month",
                        count: nil,
                        total: viewModel.paidThisMonth,
                        icon: "checkmark.circle",
                        color: .green
                    )
                }
                .padding(.horizontal)

                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(InvoiceFilter.allCases) { filter in
                            FilterPill(
                                title: filter.rawValue,
                                count: countForFilter(filter),
                                isSelected: viewModel.selectedFilter == filter
                            ) {
                                viewModel.selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Invoices List
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else if viewModel.filteredInvoices.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredInvoices) { invoice in
                            InvoiceCard(invoice: invoice)
                                .onTapGesture {
                                    selectedInvoice = invoice
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await viewModel.loadInvoices()
        }
        .task {
            await viewModel.loadInvoices()
        }
    }

    private func countForFilter(_ filter: InvoiceFilter) -> Int {
        switch filter {
        case .outstanding:
            return viewModel.invoices.filter { $0.status == .sent || $0.status == .overdue }.count
        case .all:
            return viewModel.invoices.count
        case .drafts:
            return viewModel.invoices.filter { $0.status == .draft }.count
        case .paid:
            return viewModel.invoices.filter { $0.status == .paid }.count
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.alphaSecondaryText)

            Text("No invoices yet")
                .font(.alphaBody)
                .foregroundColor(.alphaSecondaryText)

            Text("Tap + to create your first invoice")
                .font(.alphaBodySmall)
                .foregroundColor(.alphaTertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isSelected ? .white : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .foregroundColor(isSelected ? Color(uiColor: .systemBackground) : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color(uiColor: .label) : Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(20)
        }
    }
}

// MARK: - Billing Summary Card

struct BillingSummaryCard: View {
    let title: String
    let count: Int?
    let total: Double
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)

                Spacer()

                if let count = count {
                    Text("\(count)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.alphaPrimaryText)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.alphaSecondaryText)

                Text(String(format: "$%.2f", total))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.alphaPrimaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.alphaCardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Invoice Card

struct InvoiceCard: View {
    let invoice: Invoice
    var compact: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            // Header Row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(invoice.invoiceNumber)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.alphaPrimaryText)

                    if let client = invoice.client {
                        Text(client.name)
                            .font(.system(size: 14))
                            .foregroundColor(.alphaSecondaryText)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(invoice.totalFormatted)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.alphaPrimaryText)

                    statusBadge
                }
            }

            if !compact {
                Divider()

                // Details Row
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Due Date")
                            .font(.system(size: 12))
                            .foregroundColor(.alphaSecondaryText)

                        Text(invoice.dueDate, style: .date)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.alphaPrimaryText)
                    }

                    Spacer()

                    if invoice.isOverdue {
                        Label {
                            Text("Overdue by \(-invoice.daysUntilDue) days")
                                .font(.system(size: 12, weight: .medium))
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                        }
                        .foregroundColor(.alphaError)
                    } else if invoice.status == .sent {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Days Until Due")
                                .font(.system(size: 12))
                                .foregroundColor(.alphaSecondaryText)

                            Text("\(invoice.daysUntilDue)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.alphaPrimaryText)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.alphaCardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(invoice.isOverdue ? Color.alphaError.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }

    private var statusBadge: some View {
        Text(invoice.status.displayName)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(6)
    }

    private var statusColor: Color {
        switch invoice.status {
        case .draft:
            return .gray
        case .sent:
            return .blue
        case .paid:
            return .green
        case .overdue:
            return .red
        case .cancelled:
            return .gray
        }
    }
}

// MARK: - Billing Rules Content

struct BillingRulesContent: View {
    @StateObject private var viewModel = BillingRulesViewModel()

    var body: some View {
        List {
            // Active Projects Section
            if !viewModel.filteredActiveProjects.isEmpty {
                Section {
                    ForEach(viewModel.filteredActiveProjects) { project in
                        NavigationLink {
                            ProjectBillingEditView(project: project) {
                                Task {
                                    await viewModel.loadProjects()
                                }
                            }
                        } label: {
                            ProjectBillingRow(project: project)
                        }
                    }
                } header: {
                    Text("Active Projects")
                }
            }

            // Inactive Projects Section
            if !viewModel.filteredInactiveProjects.isEmpty {
                Section {
                    ForEach(viewModel.filteredInactiveProjects) { project in
                        NavigationLink {
                            ProjectBillingEditView(project: project) {
                                Task {
                                    await viewModel.loadProjects()
                                }
                            }
                        } label: {
                            ProjectBillingRow(project: project)
                        }
                    }
                } header: {
                    Text("Inactive Projects")
                }
            }

            // Empty State
            if viewModel.projects.isEmpty && !viewModel.isLoading {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "folder")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("No projects yet")
                            .font(.body)
                            .foregroundColor(.secondary)

                        Text("Create a project to configure billing rules")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search projects")
        .refreshable {
            await viewModel.loadProjects()
        }
        .task {
            await viewModel.loadProjects()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}

// MARK: - Billing Rules Sheet

struct BillingRulesSheet: View {
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            BillingRulesContent()
                .navigationTitle("Billing Rules")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            isPresented = false
                        }
                    }
                }
        }
    }
}

// MARK: - Project Billing Row

struct ProjectBillingRow: View {
    let project: Project

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: project.color ?? "#007AFF"))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    if let client = project.client {
                        Text(client.name)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    Text(project.billingModel.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .cornerRadius(4)
                }
            }

            Spacer()

            if project.rate != nil {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(project.displayRate)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)

                    if let budget = project.budget, budget > 0 {
                        Text(String(format: "Budget: $%.0f", budget))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Invoice Detail Sheet

struct InvoiceDetailSheet: View {
    let invoice: Invoice
    var onUpdate: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isUpdating = false
    @State private var errorMessage: String?

    private let invoiceRepository = InvoiceRepository()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Status Header
                    VStack(spacing: 8) {
                        Text(invoice.totalFormatted)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primary)

                        statusBadge
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))

                    // Invoice Info & Bill To
                    VStack(spacing: 16) {
                        DetailRow(label: "Invoice Number", value: invoice.invoiceNumber)

                        Divider()

                        // Bill To Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bill To")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            if let client = invoice.client {
                                Text(client.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)

                                if let email = client.email {
                                    Text(email)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Unknown Client")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Divider()

                        DetailRow(label: "Issue Date", value: invoice.issueDate.formatted(date: .abbreviated, time: .omitted))
                        DetailRow(label: "Due Date", value: invoice.dueDate.formatted(date: .abbreviated, time: .omitted))

                        if let project = invoice.project {
                            DetailRow(label: "Project", value: project.name)
                        }

                        if invoice.isOverdue {
                            HStack {
                                Text("Status")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Label("Overdue by \(-invoice.daysUntilDue) days", systemImage: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Line Items Section
                    if let lineItems = invoice.lineItems, !lineItems.isEmpty {
                        VStack(spacing: 0) {
                            // Header
                            HStack {
                                Text("Description")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("Qty")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .trailing)

                                Text("Rate")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 70, alignment: .trailing)

                                Text("Amount")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(width: 80, alignment: .trailing)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(uiColor: .tertiarySystemGroupedBackground))

                            // Line Items
                            ForEach(lineItems) { item in
                                HStack(alignment: .top) {
                                    Text(item.description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(2)

                                    Text(String(format: "%.0f", item.quantity))
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary)
                                        .frame(width: 40, alignment: .trailing)

                                    Text(String(format: "$%.2f", item.rate))
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary)
                                        .frame(width: 70, alignment: .trailing)

                                    Text(String(format: "$%.2f", item.amount))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary)
                                        .frame(width: 80, alignment: .trailing)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                                if item.id != lineItems.last?.id {
                                    Divider()
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Totals Section
                    VStack(spacing: 12) {
                        DetailRow(label: "Subtotal", value: String(format: "$%.2f", invoice.subtotal))

                        if let taxRate = invoice.taxRate, let taxAmount = invoice.taxAmount {
                            DetailRow(label: "Tax (\(String(format: "%.1f%%", taxRate * 100)))", value: String(format: "$%.2f", taxAmount))
                        }

                        Divider()

                        DetailRow(label: "Total", value: invoice.totalFormatted, isBold: true)

                        if let notes = invoice.notes, !notes.isEmpty {
                            Divider()
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Notes")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Text(notes)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Action Buttons
                    VStack(spacing: 12) {
                        if invoice.status == .draft {
                            Button(action: { Task { await sendInvoice() } }) {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                    Text("Send Invoice")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }

                        if invoice.status == .sent || invoice.status == .overdue {
                            Button(action: { Task { await markAsPaid() } }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Mark as Paid")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }

                        if invoice.status == .paid, let paidAt = invoice.paidAt {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Paid on \(paidAt.formatted(date: .abbreviated, time: .omitted))")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }

                        // Download PDF Button
                        Button(action: { /* TODO: Implement PDF generation */ }) {
                            HStack {
                                Image(systemName: "arrow.down.doc.fill")
                                Text("Download PDF")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(uiColor: .separator), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Invoice Details")
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
        }
    }

    private var statusBadge: some View {
        Text(invoice.status.displayName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor)
            .cornerRadius(8)
    }

    private var statusColor: Color {
        switch invoice.status {
        case .draft: return .gray
        case .sent: return .blue
        case .paid: return .green
        case .overdue: return .red
        case .cancelled: return .gray
        }
    }

    private func sendInvoice() async {
        isUpdating = true
        errorMessage = nil

        do {
            _ = try await invoiceRepository.sendInvoice(id: invoice.id)
            onUpdate()
            dismiss()
        } catch {
            errorMessage = "Failed to send invoice: \(error.localizedDescription)"
        }

        isUpdating = false
    }

    private func markAsPaid() async {
        isUpdating = true
        errorMessage = nil

        do {
            _ = try await invoiceRepository.markAsPaid(id: invoice.id)
            onUpdate()
            dismiss()
        } catch {
            errorMessage = "Failed to update invoice: \(error.localizedDescription)"
        }

        isUpdating = false
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    var isBold: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .fontWeight(isBold ? .semibold : .regular)
                .foregroundColor(.primary)
        }
        .font(.system(size: 15))
    }
}

// MARK: - Preview

#Preview("Billing View") {
    BillingView()
        .environmentObject({
            let state = AppState()
            state.isAuthenticated = true
            state.currentUser = .preview
            return state
        }())
}
