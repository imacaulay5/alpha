//
//  ProjectFormSheet.swift
//  alpha
//
//  Created by Claude Code on 1/30/26.
//

import SwiftUI

// MARK: - Project Create/Update DTO

struct ProjectCreate: Codable {
    var name: String
    var description: String?
    var clientId: String?
    var billingModel: String
    var rate: Double?
    var budget: Double?
    var startDate: Date?
    var endDate: Date?
    var color: String?
    var isActive: Bool = true

    enum CodingKeys: String, CodingKey {
        case name, description, rate, budget, color
        case clientId = "client_id"
        case billingModel = "billing_model"
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
    }
}

// MARK: - ProjectFormSheet

struct ProjectFormSheet: View {
    @Binding var isPresented: Bool
    var project: Project?
    var onSave: () -> Void

    // Form fields
    @State private var name: String
    @State private var description: String
    @State private var selectedClientId: String?
    @State private var billingModel: BillingModel
    @State private var rate: String
    @State private var hasBudget: Bool
    @State private var budget: String
    @State private var hasStartDate: Bool
    @State private var startDate: Date
    @State private var hasEndDate: Bool
    @State private var endDate: Date
    @State private var selectedColor: String

    // State
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var clients: [Contact] = []
    @State private var isLoadingClients = true

    private let apiClient = APIClient.shared

    // Available project colors
    private let projectColors = [
        "#3B82F6", // Blue
        "#10B981", // Green
        "#F59E0B", // Amber
        "#EF4444", // Red
        "#8B5CF6", // Purple
        "#EC4899", // Pink
        "#06B6D4", // Cyan
        "#F97316", // Orange
    ]

    init(isPresented: Binding<Bool>, project: Project? = nil, onSave: @escaping () -> Void) {
        self._isPresented = isPresented
        self.project = project
        self.onSave = onSave

        // Initialize state from project if editing
        _name = State(initialValue: project?.name ?? "")
        _description = State(initialValue: project?.description ?? "")
        _selectedClientId = State(initialValue: project?.clientId)
        _billingModel = State(initialValue: project?.billingModel ?? .hourly)
        _rate = State(initialValue: project?.rate != nil ? String(format: "%.2f", project!.rate!) : "")
        _hasBudget = State(initialValue: project?.budget != nil && project!.budget! > 0)
        _budget = State(initialValue: project?.budget != nil ? String(format: "%.2f", project!.budget!) : "")
        _hasStartDate = State(initialValue: project?.startDate != nil)
        _startDate = State(initialValue: project?.startDate ?? Date())
        _hasEndDate = State(initialValue: project?.endDate != nil)
        _endDate = State(initialValue: project?.endDate ?? Date().addingTimeInterval(30 * 24 * 60 * 60))
        _selectedColor = State(initialValue: project?.color ?? "#3B82F6")
    }

    var body: some View {
        NavigationStack {
            Form {
                // Project Information
                Section("Project Information") {
                    TextField("Project Name", text: $name)

                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)

                    // Client Picker
                    Picker("Client", selection: $selectedClientId) {
                        Text("No Client").tag(nil as String?)
                        ForEach(clients) { client in
                            Text(client.name).tag(client.id as String?)
                        }
                    }

                    // Color Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Project Color")
                            .font(.subheadline)
                            .foregroundColor(.alphaSecondaryText)

                        HStack(spacing: 12) {
                            ForEach(projectColors, id: \.self) { colorHex in
                                Circle()
                                    .fill(Color(hex: colorHex))
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        if selectedColor == colorHex {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .onTapGesture {
                                        selectedColor = colorHex
                                    }
                            }
                        }
                    }
                }

                // Billing Configuration
                Section("Billing Configuration") {
                    Picker("Billing Model", selection: $billingModel) {
                        ForEach(BillingModel.allCases, id: \.self) { model in
                            Text(model.displayName).tag(model)
                        }
                    }

                    if billingModel != .notBillable {
                        HStack {
                            Text(rateLabel)
                                .foregroundColor(.alphaSecondaryText)

                            Spacer()

                            HStack(spacing: 4) {
                                Text("$")
                                    .foregroundColor(.alphaSecondaryText)

                                TextField("0.00", text: $rate)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                            }
                        }
                    }

                    // Budget
                    Toggle("Set Budget", isOn: $hasBudget)

                    if hasBudget {
                        HStack {
                            Text("Budget Amount")
                                .foregroundColor(.alphaSecondaryText)

                            Spacer()

                            HStack(spacing: 4) {
                                Text("$")
                                    .foregroundColor(.alphaSecondaryText)

                                TextField("0.00", text: $budget)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                            }
                        }
                    }
                }

                // Project Dates
                Section("Project Dates (Optional)") {
                    Toggle("Start Date", isOn: $hasStartDate)

                    if hasStartDate {
                        DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    }

                    Toggle("End Date", isOn: $hasEndDate)

                    if hasEndDate {
                        DatePicker("End", selection: $endDate, displayedComponents: .date)
                    }
                }

                // Error message
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.alphaBodySmall)
                            .foregroundColor(.alphaError)
                    }
                }
            }
            .navigationTitle(project == nil ? "New Project" : "Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(project == nil ? "Create" : "Save") {
                        Task {
                            await saveProject()
                        }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
            .overlay {
                if isSaving {
                    ProgressView()
                }
            }
            .task {
                await loadClients()
            }
        }
    }

    // MARK: - Computed Properties

    private var rateLabel: String {
        switch billingModel {
        case .hourly:
            return "Hourly Rate"
        case .fixed:
            return "Fixed Price"
        case .retainer:
            return "Monthly Rate"
        case .milestone:
            return "Milestone Amount"
        case .taskBased:
            return "Rate per Task"
        case .notBillable:
            return "Rate"
        }
    }

    // MARK: - Methods

    private func loadClients() async {
        isLoadingClients = true
        do {
            clients = try await apiClient.get("/clients?is_active=true")
        } catch {
            // Silently fail - user can still create project without client
            clients = []
        }
        isLoadingClients = false
    }

    private func saveProject() async {
        isSaving = true
        errorMessage = nil

        do {
            let projectData = ProjectCreate(
                name: name,
                description: description.isEmpty ? nil : description,
                clientId: selectedClientId,
                billingModel: billingModel.rawValue,
                rate: Double(rate),
                budget: hasBudget ? Double(budget) : nil,
                startDate: hasStartDate ? startDate : nil,
                endDate: hasEndDate ? endDate : nil,
                color: selectedColor,
                isActive: true
            )

            if let existingProject = project {
                // Update existing project
                let _: Project = try await apiClient.put("/projects/\(existingProject.id)", body: projectData)
            } else {
                // Create new project
                let _: Project = try await apiClient.post("/projects", body: projectData)
            }

            onSave()
            isPresented = false
        } catch {
            errorMessage = "Failed to save project: \(error.localizedDescription)"
        }

        isSaving = false
    }
}

// MARK: - BillingModel CaseIterable

extension BillingModel: CaseIterable {
    static var allCases: [BillingModel] {
        [.hourly, .fixed, .retainer, .milestone, .taskBased, .notBillable]
    }
}

// MARK: - Preview

#Preview("New Project") {
    ProjectFormSheet(isPresented: .constant(true), onSave: {})
}

#Preview("Edit Project") {
    ProjectFormSheet(isPresented: .constant(true), project: .preview, onSave: {})
}
