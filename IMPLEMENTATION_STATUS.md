# Alpha iOS App - Implementation Status

**Last Updated**: December 17, 2025
**Project**: Contractor Billing & Time Tracking iOS App (Reorganization)
**Status**: App Reorganization In Progress (~80% Complete)

---

## 🎯 Project Overview

Native iOS application for contractor time tracking, expense management, and billing with AI-powered features.

**Tech Stack**:
- **iOS**: SwiftUI, iOS 17+, MVVM Architecture
- **Backend**: FastAPI, SQLAlchemy, SQLite/PostgreSQL
- **AI**: OpenAI GPT-4 Mini (planned integration)

---

## ✅ COMPLETED PHASES

### Phase 1: Foundation & Core Infrastructure ✅ (100%)

**iOS App**:
- ✅ All data models (10 files)
  - Role, Organization, User, Client, Project, Task, TimeEntry, Expense, Invoice, AnyCodable
  - Full Codable conformance with snake_case ↔ camelCase mapping
  - Computed properties and preview helpers
- ✅ Networking layer
  - APIClient with generic async/await methods
  - JWT token injection
  - Error handling with typed errors
- ✅ Authentication services
  - KeychainHelper for secure token storage
  - AuthService for login/logout/token refresh
- ✅ Design system
  - Colors with semantic naming and status colors
  - Typography scale (Display, Headline, Title, Body, Label, Caption)
  - Hex color support
- ✅ Reusable components
  - AlphaButton (4 styles, 3 sizes, loading/disabled states)
  - AlphaCard with convenience modifiers
- ✅ App architecture
  - AppState for global state management
  - AppCoordinator for navigation flow
  - Updated alphaApp.swift entry point

**Files Created**: 26 Swift files
**Estimated Time**: 8-12 hours ✅
**Actual Time**: ~10 hours

---

### Phase 2: Backend API Development ✅ (100%)

**Backend Infrastructure**:
- ✅ Project structure with organized folders
  - models/, schemas/, routers/, services/
- ✅ Database configuration
  - SQLAlchemy setup
  - SQLite default (PostgreSQL-ready)
- ✅ Configuration management
  - Environment variables (.env)
  - Settings with Pydantic

**Database Models**:
- ✅ Organization model
- ✅ User model with password hashing
- ✅ Client model
- ✅ Project model (6 billing types)
- ✅ Task model
- ✅ TimeEntry model (status, source enums)
- ✅ Expense model (category, status enums)

**API Endpoints**:
- ✅ Authentication
  - POST /api/v1/auth/login
  - POST /api/v1/auth/refresh
  - GET /api/v1/auth/me
- ✅ Time Entries
  - GET /api/v1/time-entries/today
  - POST /api/v1/time-entries
  - DELETE /api/v1/time-entries/{id}
- ✅ Expenses
  - GET /api/v1/expenses
  - POST /api/v1/expenses
  - DELETE /api/v1/expenses/{id}
- ✅ Projects & Tasks
  - GET /api/v1/projects
  - GET /api/v1/projects/{id}/tasks
- ✅ Dashboard
  - GET /api/v1/dashboard/metrics

**Additional**:
- ✅ JWT authentication with refresh tokens
- ✅ Password hashing with bcrypt
- ✅ CORS configuration
- ✅ Database seed script with test data
  - 1 organization
  - 2 test users (demo@alpha.com, admin@alpha.com)
  - 2 clients
  - 3 projects (hourly, fixed, retainer)
  - 8 tasks
  - 2 time entries
  - 2 expenses

**Files Created**: 15+ Python files
**Estimated Time**: 12-16 hours ✅
**Actual Time**: ~14 hours

---

### Phase 3: Authentication & Navigation ✅ (100%)

**iOS Views**:
- ✅ LoginView
  - Email and password fields
  - Form validation
  - Error messaging
  - Loading states
  - Mock login bypass for UI testing (demo@alpha.com / demo123)
  - Forgot password link (placeholder)
  - Sign up link (placeholder)
- ✅ MainTabView
  - 4-tab navigation (Dashboard, Time, Expenses, Settings)
  - Custom tint color
  - Tab bar appearance configuration
- ✅ AppCoordinator updated
  - Removed placeholder views
  - Routes to real LoginView and MainTabView

**Features**:
- ✅ Login flow with authentication
- ✅ Tab-based navigation
- ✅ Sign out functionality

**Files Created**: 7 Swift files
**Estimated Time**: 4-6 hours ✅
**Actual Time**: ~5 hours

---

### Phase 4: Dashboard & Settings Views ✅ (90%)

**DashboardView**:
- ✅ Welcome header with user name and avatar
- ✅ Metrics grid (2x2)
  - Hours Today
  - Hours This Week
  - Pending Expenses
  - Pending Approvals
- ✅ Quick action buttons
  - Start Timer (placeholder action)
  - Add Expense (placeholder action)
- ✅ Pull-to-refresh support
- ✅ Empty/loading states
- ⏳ Connect to real dashboard API

**SettingsView**:
- ✅ User profile section with avatar and initials
- ✅ Organization information display
- ✅ Preferences menu items (placeholders)
  - Notifications
  - Display
  - Date & Time
- ✅ Data menu items (placeholders)
  - Export Data
  - Offline Data
- ✅ Support menu items (placeholders)
  - Help Center
  - Send Feedback
  - About
- ✅ Sign out with confirmation dialog

**Files Created**: 2 Swift files
**Status**: Mostly complete, needs API integration

---

### Phase 5: Time Tracking Features ✅ (80%)

**TimeTrackingView**:
- ✅ Timer display (HH:MM:SS format)
- ✅ Start/Stop timer functionality
  - Real-time updates every second
  - Elapsed time tracking
- ✅ Project/Task selection (UI ready, needs data)
- ✅ Notes field
- ✅ Today's entries section
  - Empty state with helpful message
  - ⏳ Entry list (needs API integration)
- ✅ Pull-to-refresh

**TimeTrackingViewModel**:
- ✅ Timer state management
- ✅ Timer start/stop logic
- ⏳ Save timer to API on stop
- ⏳ Load today's entries from API
- ⏳ Load projects from API
- ⏳ Delete entry

**Files Created**: 1 Swift file
**Status**: Core timer works, needs API integration

---

### Phase 6: Expense Management ✅ (75%)

**ExpenseView**:
- ✅ Summary card
  - Total expenses (placeholder $0.00)
  - Pending count
- ✅ Expense list section
  - Empty state with helpful message
  - ⏳ Expense cards (needs API integration)
- ✅ Add button in navigation bar
- ✅ Sheet presentation for add expense
- ✅ Pull-to-refresh

**ExpenseViewModel**:
- ✅ Expenses state management
- ⏳ Load expenses from API
- ⏳ Create expense
- ⏳ Delete expense

**Files Created**: 1 Swift file
**Status**: UI complete, needs API integration and add form

---

## ⏳ IN PROGRESS / PARTIALLY COMPLETE

### API Integration (100%)

**What Works**:
- ✅ Backend server runs on Python 3.13 with virtual environment
- ✅ All authentication endpoints functional (login, refresh, me)
- ✅ Database seeded with test data
- ✅ Mock login removed from iOS app
- ✅ LoginView connected to real backend API
- ✅ TimeTrackingViewModel connected to backend
  - Load today's entries
  - Save time entries
  - Delete time entries
- ✅ ExpenseViewModel connected to backend
  - Load expenses
  - Calculate totals and pending count
  - Delete expenses
- ✅ DashboardViewModel connected to backend
  - Load real metrics (hours today, hours week, pending expenses, pending approvals)
- ✅ Error handling in all ViewModels
- ✅ APIClient delete method with response support

**What Still Needs Work**:
- ⏳ Test end-to-end login flow in iOS Simulator
- ⏳ Test time entry creation flow
- ⏳ Test expense loading
- ⏳ Add projects/tasks loading to TimeTrackingView
- ⏳ Build add expense form
- ⏳ Add retry logic for failed requests

**Estimated Time Remaining**: 2-3 hours

---

## 🔄 APP REORGANIZATION (IN PROGRESS)

### Major Restructure: Timer-Focused → Task Logging/Billing-Focused

**Goal**: Transform the app from a timer-centric interface to a task logging and billing-focused interface.

**Timeline**: December 16-27, 2025 (10-13 days)
**Current Phase**: Phase 5 - Home View Updates & Polish (Ready to Start)

---

#### **Phase 1: Foundation & Quick Entry** ✅ (100%)

**Components to Create**:
- ✅ FloatingActionButton component (global FAB on all tabs)
- ✅ QuickEntrySheet with ViewModel (quick time entry form)
- ⏳ TimeEntryRow component (will be created in Phase 2)

**Tab Restructure**:
- ✅ Update MainTabView: Dashboard → Home, Time → Tasks, Add Billing tab
- ✅ Add FAB overlay to MainTabView (ZStack wrapper)
- ✅ Update tab icons and labels

**Assets & Branding**:
- ✅ Configure Assets.xcassets with green primary color
- ✅ Create Primary.colorset (light: RGB 52, 199, 89 / dark: RGB 60, 209, 102)
- ✅ Create Secondary.colorset (complementary green)
- ✅ Update AccentColor.colorset to match Primary
- ✅ Update FAB and tab tint to use .alphaPrimary

**Backend**:
- ✅ Add GET `/time-entries` endpoint with filtering (start_date, end_date, project_id)

**Files Created**:
- `/Users/iver/Projects/alpha/alpha/Shared/Components/FloatingActionButton.swift`
- `/Users/iver/Projects/alpha/alpha/Shared/Components/QuickEntrySheet.swift`
- `/Users/iver/Projects/alpha/alpha/Shared/Components/QuickEntryViewModel.swift`
- `/Users/iver/Projects/alpha/alpha/Features/Billing/BillingView.swift` (placeholder)
- `/Users/iver/Projects/alpha/alpha/Assets.xcassets/Primary.colorset/Contents.json`
- `/Users/iver/Projects/alpha/alpha/Assets.xcassets/Secondary.colorset/Contents.json`

**Files Modified**:
- `/Users/iver/Projects/alpha/alpha/Features/Dashboard/MainTabView.swift`
- `/Users/iver/Projects/alpha/alpha/Assets.xcassets/AccentColor.colorset/Contents.json`
- `/Users/iver/Projects/alpha-backend/app/routers/time_entries.py`
- `/Users/iver/Projects/alpha/alpha/Core/Models/Project.swift` (added Hashable)
- `/Users/iver/Projects/alpha/alpha/Core/Models/Client.swift` (added Hashable)
- `/Users/iver/Projects/alpha/alpha/Core/Models/Task.swift` (added Hashable)

**Bugs Fixed**:
- ✅ Missing Combine import in QuickEntryViewModel
- ✅ Hashable conformance for Picker tag values
- ✅ Sendable closure warning in TimeTrackingView timer
- ✅ Backend tags field mismatch
- ✅ UI visibility issues with hardcoded blue colors

**Status**: ✅ Complete
**Actual Time**: ~2 hours
**Date Completed**: December 16, 2025

---

#### **Phase 2: Tasks View** ✅ (100%)

**Folder Restructure**:
- ✅ Renamed `Features/TimeTracking/` → `Features/Tasks/`
- ✅ Removed timer functionality completely (no more running timer UI)

**Components Created**:
- ✅ TasksView and TasksViewModel (grouped time entries)
- ✅ ProjectGroupView (project header with totals)
- ✅ TaskGroupView (task subtotals)
- ✅ BillingPeriodPicker (This Week, This Month, Last Month, Custom)
- ✅ TimeEntryRow (with swipe-to-delete)
- ✅ SummaryCard component

**Features**:
- ✅ Group time entries by Project → Task → Individual Entries
- ✅ Expand/collapse functionality for projects and tasks
- ✅ Summary cards (Total Hours, Total Billable, Projects Count)
- ✅ Pull-to-refresh support
- ✅ Automatic totals calculation at all levels
- ✅ Color-coded projects with project color badge
- ✅ Empty state with helpful message

**Additional**:
- ✅ Renamed color assets: Primary → BrandPrimary, Secondary → BrandSecondary
- ✅ Fixed asset naming conflicts with SwiftUI built-in colors

**Status**: ✅ Complete
**Actual Time**: ~1 hour
**Date Completed**: December 16, 2025

---

#### **Phase 3: Billing View** ✅ (100%)

**Components Created**:
- ✅ BillingView and BillingViewModel (full implementation)
- ✅ InvoiceCard component (with status badges, overdue warnings)
- ✅ InvoiceListSection (grouped by status)
- ✅ ExpensesSummaryCard (compact expenses view)

**Features**:
- ✅ Outstanding Invoices section (prominent display)
- ✅ Recent Invoices section (last 5 paid)
- ✅ Expenses overview with link to full tab
- ✅ Summary cards (Outstanding total, Pending expenses)
- ✅ Parallel async data loading with withTaskGroup

**Backend**:
- ✅ Created Invoice model with InvoiceStatusEnum
- ✅ Added GET `/invoices` endpoint (filter by status, client_id, pagination)
- ✅ Added Invoice relationships to Organization, Client, Project models
- ✅ Registered invoices router in main.py

**Files Created**:
- `/Users/iver/Projects/alpha/alpha/Features/Billing/BillingView.swift`
- `/Users/iver/Projects/alpha/alpha/Features/Billing/BillingViewModel.swift`
- `/Users/iver/Projects/alpha/alpha/Features/Billing/Components/InvoiceCard.swift`
- `/Users/iver/Projects/alpha-backend/app/models/invoice.py`
- `/Users/iver/Projects/alpha-backend/app/routers/invoices.py`

**Status**: ✅ Complete
**Actual Time**: ~1 hour
**Date Completed**: December 16, 2025

---

#### **Phase 4: Settings Billing Rules** ✅ (100%)

**Components Created**:
- ✅ BillingRulesView and ViewModel (project billing configs with search)
- ✅ ProjectBillingEditView and ViewModel (full billing configuration form)
- ✅ ProjectBillingCard (project list item with color, client, billing model)

**Features**:
- ✅ List all projects with billing configuration
- ✅ Search/filter projects
- ✅ Active/Inactive project sections
- ✅ Edit billing model, rate, budget per project
- ✅ Dynamic rate label based on billing model
- ✅ Billing model descriptions (6 models)
- ✅ Form validation and error handling
- ✅ Pull-to-refresh support

**Backend**:
- ✅ Added PATCH `/projects/{id}` endpoint (update billing config)
- ✅ UpdateProjectBillingRequest schema with snake_case mapping

**Settings**:
- ✅ Added "Billing Rules" link to Settings tab in new "Billing" section

**Additional**:
- ✅ Added patch() method to APIClient.swift

**Files Created**:
- `/Users/iver/Projects/alpha/alpha/Features/Settings/BillingRulesView.swift`
- `/Users/iver/Projects/alpha/alpha/Features/Settings/ProjectBillingEditView.swift`

**Files Modified**:
- `/Users/iver/Projects/alpha/alpha/Features/Settings/SettingsView.swift`
- `/Users/iver/Projects/alpha/alpha/Core/Networking/APIClient.swift`
- `/Users/iver/Projects/alpha-backend/app/routers/projects.py`

**Status**: ✅ Complete
**Actual Time**: ~1 hour
**Date Completed**: December 17, 2025

---

#### **Phase 5: Home View Updates & Polish** ⏳ (0%)

**Folder Restructure**:
- ⏳ Rename `Features/Dashboard/` → `Features/Home/`

**Updates**:
- ⏳ Update HomeView (was DashboardView)
  - Remove "Start Timer" quick action
  - Add "Log Time" quick action
  - Update metrics with new billing fields
- ⏳ Update ExpenseView
  - Remove toolbar "+" button (FAB handles this)
  - Improve empty state
- ⏳ Final polish
  - Add loading states to all views
  - Improve error messages
  - Test all user flows
  - Verify empty states
  - Check keyboard handling

**Status**: Not started
**Estimated Time**: 1-2 days

---

### **Reorganization Summary**

**What's Changing**:
- ❌ Removing timer functionality
- ✅ Adding floating '+' button (bottom-right, all tabs)
- ✅ New tab structure: Home, Tasks, Billing, Settings
- ✅ Primary function: Quick task logging
- ✅ Comprehensive task view with grouping
- ✅ Invoice visibility in Billing tab
- ✅ Billing rules configuration in Settings

**Files to Create**: 19 new files (14 created, 5 remaining)
**Files to Modify**: 5 files (4 modified, 1 remaining)
**Folders to Rename**: 2 folders (1 renamed, 1 remaining)
**Backend Endpoints**: 3 new, 1 modified (all complete)

**Overall Progress**: 80% (Phase 1, 2, 3, 4 complete - only Phase 5 remaining)

---

## 📋 NOT STARTED / FUTURE PHASES

### Phase 7: AI Features Integration (0%)

**Natural Language Time Entry**:
- ⏳ NLUService implementation
- ⏳ OpenAI API integration
- ⏳ Parse time entry from text
  - Extract project, task, duration, date, notes
  - Confidence scoring
- ⏳ NaturalLanguageEntryView
- ⏳ ParsedEntryConfirmationView
- ⏳ Wire up to TimeTrackingView

**Receipt OCR**:
- ⏳ OCRService implementation
- ⏳ Vision framework for text extraction
- ⏳ OpenAI for categorization
- ⏳ ReceiptScannerView with camera/photo picker
- ⏳ ExtractedReceiptConfirmationView
- ⏳ Wire up to ExpenseView

**Estimated Time**: 8-12 hours

---

### Phase 8: Enhanced Features (0%)

**Time Tracking Enhancements**:
- ⏳ Manual time entry form
- ⏳ Edit time entries
- ⏳ Project/Task picker with search
- ⏳ Time entry filters (week, month)
- ⏳ Time entry row component with full details

**Expense Enhancements**:
- ⏳ Add expense form (manual entry)
- ⏳ Edit expenses
- ⏳ Expense categories picker
- ⏳ Expense filters by status/date
- ⏳ Expense row component
- ⏳ Receipt image upload
- ⏳ Receipt image preview

**Dashboard Enhancements**:
- ⏳ Charts with Swift Charts
- ⏳ Weekly/monthly view toggle
- ⏳ Outstanding invoices alert
- ⏳ Recent activity feed

**Estimated Time**: 10-15 hours

---

### Phase 9: Offline Support (0%)

**SwiftData Integration**:
- ⏳ Create SwiftData models
- ⏳ Set up ModelContainer
- ⏳ Migration from in-memory to persistent storage

**Offline Functionality**:
- ⏳ Queue pending operations
- ⏳ Background sync when online
- ⏳ Conflict resolution
- ⏳ Offline indicator in UI

**Caching Strategy**:
- ⏳ Cache projects and tasks
- ⏳ Cache recent time entries (30 days)
- ⏳ Cache user preferences
- ⏳ TTL and invalidation logic

**Estimated Time**: 10-12 hours

---

### Phase 10: Polish & Ecosystem (0%)

**UI Polish**:
- ⏳ Loading skeletons for async content
- ⏳ Better error messages with retry buttons
- ⏳ Empty states with illustrations
- ⏳ Success toast notifications
- ⏳ Haptic feedback on actions
- ⏳ Smooth transitions and animations
- ⏳ Fix tab bar selected icon visibility issue
- ⏳ Fix login button visibility issue

**Widgets**:
- ⏳ Timer widget (start/stop from home screen)
- ⏳ Today's hours widget
- ⏳ Widget configuration

**Siri Shortcuts**:
- ⏳ "Start timer for [project]"
- ⏳ "Log hours"
- ⏳ "How many hours today?"

**Apple Watch**:
- ⏳ Watch app with timer
- ⏳ Complications
- ⏳ Haptic timer notifications

**Accessibility**:
- ⏳ VoiceOver labels
- ⏳ Dynamic type support
- ⏳ High contrast mode
- ⏳ Reduced motion support

**Estimated Time**: 15-20 hours

---

### Phase 11: Testing (0%)

**Unit Tests**:
- ⏳ API client tests
- ⏳ Auth service tests
- ⏳ NLU parsing tests (when implemented)
- ⏳ OCR extraction tests (when implemented)
- ⏳ Model decoding tests

**UI Tests**:
- ⏳ Login flow
- ⏳ Timer start/stop
- ⏳ Time entry creation
- ⏳ Expense creation
- ⏳ Navigation tests

**Integration Tests**:
- ⏳ API integration tests
- ⏳ Offline sync tests (when implemented)
- ⏳ Authentication flow tests

**Estimated Time**: 10-12 hours

---

## 🐛 KNOWN ISSUES

### High Priority
1. **Tab Bar Selected Icon**: Selected tab icon disappears behind background blur
2. **Login Button**: Sign In button may be cut off on smaller screens
3. **Mock Login**: Need to remove demo@alpha.com bypass and use real API

### Medium Priority
4. ~~**No API Integration**: ViewModels make no real API calls yet~~ ✅ RESOLVED
5. ~~**No Error Handling**: Network errors not gracefully handled~~ ✅ RESOLVED
6. ~~**No Loading States**: Missing loading indicators during API calls~~ ✅ RESOLVED
7. ~~**Color Assets**: Primary/Secondary colors not configured in Assets.xcassets~~ ✅ RESOLVED
8. **Info.plist**: Camera/photo permissions not added

### Low Priority
9. **No App Icon**: Still using default placeholder
10. **No Dark Mode Refinements**: Design system supports it but not tested
11. **No iPad Optimization**: UI designed for iPhone only

---

## 📊 Overall Progress

| Category | Progress | Status |
|----------|----------|--------|
| **Foundation** | 100% | ✅ Complete |
| **Backend API** | 100% | ✅ Complete |
| **Authentication** | 100% | ✅ Complete |
| **Navigation** | 100% | ✅ Complete |
| **Dashboard** | 90% | 🟡 Mostly Done |
| **Time Tracking** | 80% | 🟡 In Progress |
| **Expenses** | 75% | 🟡 In Progress |
| **Settings** | 90% | 🟡 Mostly Done |
| **API Integration** | 100% | ✅ Complete |
| **AI Features** | 0% | ⏳ Not Started |
| **Offline Support** | 0% | ⏳ Not Started |
| **Polish** | 10% | ⏳ Not Started |
| **Testing** | 0% | ⏳ Not Started |

**Overall MVP Completion**: ~80%

---

## 🎯 Next Immediate Steps

### **App Reorganization - Phase 5: Home View Updates & Polish** (CURRENT FOCUS)

1. **Rename Dashboard Folder** (Next - HIGH PRIORITY)
   - Rename `/Users/iver/Projects/alpha/alpha/Features/Dashboard/` → `Features/Home/`
   - Rename `DashboardView.swift` → `HomeView.swift`
   - Update imports and references throughout the app

2. **Update Home View** (HIGH PRIORITY)
   - Update title: "Dashboard" → "Home" or use welcome header without title
   - Remove "Start Timer" quick action button
   - Add "Log Time" quick action button → Opens QuickEntrySheet
   - Keep "Add Expense" button
   - Update metrics to use new dashboard API fields (if available)
   - Consider adding: Outstanding Invoices alert card

3. **Update ExpenseView** (HIGH PRIORITY)
   - Remove toolbar "+" button (FAB handles this now)
   - Improve empty state messaging
   - Ensure consistency with design system

4. **Final Polish & Testing** (HIGH PRIORITY)
   - Add loading states to all views
   - Improve error messages throughout
   - Test all user flows end-to-end:
     - Quick entry from FAB on each tab
     - Tasks view grouping and filtering
     - Billing view invoice display
     - Settings billing rules editing
   - Verify empty states are helpful
   - Check keyboard handling in all forms
   - Ensure FAB doesn't overlap content
   - Test navigation flows
   - Verify data refreshes correctly after edits

---

### **Previous Steps (Completed)**

1. **Start Backend Server** ✅ (COMPLETE)
   - ✅ Backend running on http://localhost:8000
   - ✅ Database seeded with test data
   - ✅ All authentication endpoints functional

2. **API Integration** ✅ (COMPLETE)
   - ✅ LoginView connected to backend
   - ✅ TimeTrackingViewModel connected
   - ✅ ExpenseViewModel connected
   - ✅ DashboardViewModel connected

---

## 📈 Time Tracking

| Phase | Estimated | Actual | Status |
|-------|-----------|--------|--------|
| Phase 1: Foundation | 8-12h | ~10h | ✅ |
| Phase 2: Backend | 12-16h | ~14h | ✅ |
| Phase 3: Auth/Nav | 4-6h | ~5h | ✅ |
| Phase 4-6: Features | 18-24h | ~15h | 🟡 |
| **Total So Far** | **42-58h** | **~44h** | **On Track** |
| **Remaining** | **~60-80h** | **TBD** | **Planned** |

---

## 🚀 Success Criteria

**MVP Complete When**:
- ✅ User can login (mock working, need real API)
- ⏳ User can start/stop timer and save entries
- ⏳ User can create manual time entries
- ⏳ User can view today's time entries
- ⏳ User can create expenses
- ⏳ User can view expense list
- ⏳ Dashboard shows real metrics
- ✅ User can sign out

**Nice to Have** (Post-MVP):
- AI natural language time entry
- Receipt OCR
- Offline support
- Widgets, Watch app, Siri shortcuts

---

## 📝 Notes

- **Architecture**: MVVM with Swift Concurrency working well
- **Backend**: FastAPI is fast and easy to work with
- **Database**: SQLite sufficient for MVP, easy migration to PostgreSQL
- **AI**: OpenAI integration ready, just needs wiring
- **Design**: Clean, iOS-native feel with custom components
- **Learning**: Experimental project, quality over speed

---

**Last Updated**: December 17, 2025
**Version**: 1.0.0-alpha
**Next Review**: After Phase 5 (Home View & Polish) complete
