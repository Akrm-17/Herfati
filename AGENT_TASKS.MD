```markdown
# Herfati - Craftsman Services Application

## 1. Executive Summary

Herfati is a production‑ready Flutter application that bridges **clients** with skilled **craftsmen** (electricians, plumbers, carpenters, painters, blacksmiths, etc.). The platform streamlines service discovery, ordering, real‑time communication, and administrative oversight through three distinct user roles.

| Role | Core Capabilities |
|------|-------------------|
| **Client** | Search/filter craftsmen, view detailed profiles, request services, track orders in real time, chat, rate & review, manage personal profile |
| **Craftsman** | Manage professional profile, showcase portfolio (images), accept/reject service orders, update order status, chat with clients, view earnings summary |
| **Admin** | Full user management (activate/deactivate/delete), order oversight (resolve disputes, force cancel), analytics dashboard, export reports (CSV) |

---

## 2. Design System & Branding

All UI components must strictly follow the identity below.

| Element | Value | Usage |
|---------|-------|-------|
| **Primary Gold** | `#C79A4D` | Buttons, icons, highlights, active states |
| **Primary Dark Blue** | `#1B2A4A` | AppBar, bottom nav, cards, secondary buttons |
| **Background** | White / off-white (`#F8F9FA`) | Main screen backgrounds |
| **Glassmorphism** | Enabled | Cards, dialogs, bottom sheets (backdrop‑filter blur) |
| **UI Language** | Arabic (right‑to‑left) | All user‑facing text |
| **Code Comments** | English | Variables, functions, classes |

---

## 3. Technology Stack

| Layer | Technology | Version / Notes |
|-------|------------|----------------|
| Frontend | Flutter (Dart) | Latest stable (3.22+) |
| Backend & Database | Firebase | Cloud Firestore (NoSQL) |
| Authentication | Firebase Auth | Email/Password only (no phone) |
| File Storage | Firebase Storage | For profile images & portfolio |
| State Management | Provider **or** GetX | Choose one – be consistent |
| HTTP Client | `http` or `dio` | For future API extensions |
| Local Storage | `shared_preferences` | Store session tokens, user preferences |

---

## 4. Database Collections (Firestore)

All collection names, document fields, and data types are mandatory.

### 4.1 `users`

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Firebase Auth UID (document ID) |
| `name` | String | Full name |
| `email` | String | Unique, used for login |
| `role` | String | `client` / `craftsman` / `admin` |
| `phone` | String | Optional, can be empty |
| `profileImage` | String | Firebase Storage URL |
| `createdAt` | Timestamp | Account creation date |
| `isActive` | Boolean | Admin can deactivate accounts |

### 4.2 `craftsmen` (document ID = same as `users.id`)

| Field | Type | Description |
|-------|------|-------------|
| `skills` | List\<String\> | e.g., `["Electrician", "Plumbing"]` |
| `rating` | Double | Average rating (0.0 – 5.0) |
| `totalOrders` | Integer | Completed orders count |
| `location` | String | City or district name |
| `yearsOfExperience` | Integer | Years in profession |
| `bio` | String | Short description (max 200 chars) |
| `portfolioImages` | List\<String\> | URLs from Firebase Storage |

### 4.3 `orders`

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Auto‑generated document ID |
| `clientId` | String | Reference to `users.id` |
| `craftsmanId` | String | Reference to `craftsmen.id` |
| `serviceDescription` | String | What the client needs |
| `status` | String | `pending` / `accepted` / `rejected` / `completed` / `cancelled` |
| `price` | Double | Agreed price (optional, can be 0) |
| `createdAt` | Timestamp | Order creation time |
| `scheduledDate` | Timestamp | Preferred service date |

### 4.4 `services` (read‑only reference data)

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Auto‑generated |
| `name` | String | e.g., `"Electrician"` |
| `description` | String | Short explanation |
| `category` | String | `electrical`, `plumbing`, `carpentry`, `painting`, `metalwork` |
| `imageUrl` | String | Icon or illustration URL |

### 4.5 `reviews`

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Auto‑generated |
| `orderId` | String | Reference to `orders.id` |
| `reviewerId` | String | Client who writes the review |
| `craftsmanId` | String | Craftsman being reviewed |
| `rating` | Integer | 1 – 5 stars |
| `comment` | String | Review text |
| `createdAt` | Timestamp | Review date |

### 4.6 `chat_messages` (real‑time)

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Auto‑generated |
| `orderId` | String | Which order the chat belongs to |
| `senderId` | String | `clientId` or `craftsmanId` |
| `message` | String | Text content |
| `timestamp` | Timestamp | Sent time |
| `isRead` | Boolean | Read receipt (optional) |

---

## 5. Folder Structure (Strict)

All files must be placed exactly as shown.

```
lib/
├── core/
│   ├── constants.dart          # Colors, route names, Firebase collections
│   ├── themes.dart             # Light theme (Gold + Dark Blue)
│   ├── utils.dart              # Email validator, date formatter, helpers
│   └── widgets.dart            # CustomButton, CustomInputField, LoadingOverlay
│
├── data/
│   ├── models.dart             # All models with toJson / fromJson
│   └── firebase_service.dart   # All Firestore / Auth methods
│
├── presentation/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   │
│   ├── client/
│   │   ├── home_screen.dart
│   │   ├── craftsman_profile_screen.dart
│   │   ├── my_orders_screen.dart
│   │   ├── chat_screen.dart
│   │   └── profile_screen.dart
│   │
│   ├── craftsman/
│   │   ├── home_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── orders_screen.dart
│   │   └── chat_screen.dart
│   │
│   └── admin/
│       ├── dashboard_screen.dart
│       ├── users_screen.dart
│       ├── orders_screen.dart
│       └── reports_screen.dart
│
├── app.dart                     # MaterialApp, routes, theme
└── main.dart                    # Firebase init, runApp()
```

---

## 6. Sequential Task List (Execute in Exact Order)

### Task 1 – Project Structure
Create every folder and empty file listed in section 5.  
Inside each `*_screen.dart` put a **minimal StatelessWidget**:

```dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Home Screen - Under Development')),
    );
  }
}
```

### Task 2 – Firebase Dependencies
Add to `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.17.0
  firebase_storage: ^11.6.0
  provider: ^6.1.1
  shared_preferences: ^2.2.2
  image_picker: ^1.0.7
```

Run `flutter pub get`.  
Run `flutterfire configure` (user will provide Firebase project).  
In `main.dart`: ensure `WidgetsFlutterBinding.ensureInitialized()` and `await Firebase.initializeApp()` before `runApp()`.

### Task 3 – Data Models (`models.dart`)
Write **all** classes with `toJson()` and `fromJson()`:

- `User`
- `Craftsman` (extends `User`)
- `Order`
- `Service`
- `Review`
- `ChatMessage`

Use `enum` for `role` and `status` fields.

### Task 4 – Firebase Service (`firebase_service.dart`)
Implement **every** method below with `try-catch`, `Snackbar` error messages, and `CircularProgressIndicator` in UI later.

#### Auth
- `Future<User?> signInWithEmail(String email, String password)`
- `Future<User?> signUpWithEmail(String name, String email, String password, String role)`
- `Future<void> signOut()`
- `Future<User?> getCurrentUser()`

#### Craftsman
- `Future<Craftsman?> getCraftsmanProfile(String craftsmanId)`
- `Future<List<Craftsman>> getCraftsmenByCategory(String category)`
- `Future<List<Craftsman>> getRecommendedCraftsmen()`

#### Order
- `Future<Order> createOrder(Order order)`
- `Future<List<Order>> getClientOrders(String clientId)`
- `Future<List<Order>> getCraftsmanOrders(String craftsmanId)`
- `Future<void> updateOrderStatus(String orderId, String status)`

#### Chat
- `Stream<List<ChatMessage>> getChatMessages(String orderId)`
- `Future<void> sendChatMessage(ChatMessage message)`

#### Review
- `Future<List<Review>> getCraftsmanReviews(String craftsmanId)`
- `Future<void> addReview(Review review)`

### Task 5 – Login Screen (`login_screen.dart`)
StatefulWidget with:
- `TextFormField` email + password
- Gold (`#C79A4D`) login button
- "Create account" → navigates to `SignupScreen`
- Loading indicator while calling `signInWithEmail`
- On error: `ScaffoldMessenger` shows red `SnackBar`
- On success: navigate to role‑specific home:
  - `client` → `ClientHomeScreen`
  - `craftsman` → `CraftsmanHomeScreen`
  - `admin` → `AdminDashboardScreen`

### Task 6 – Signup Screen (`signup_screen.dart`)
StatefulWidget with:
- Fields: name, email, password, confirm password
- Role selector: `SegmentedButton<String>` (client / craftsman)
- Validation: password == confirm password
- On success: call `signUpWithEmail`, then navigate to `LoginScreen`

### Task 7 – Client Home Screen (`client/home_screen.dart`)
- `AppBar` with chat (`Icons.chat`) and profile (`Icons.person`) icons
- Search bar (`TextField` with search icon)
- Horizontal category list (`ListView.builder`) – Electrician, Plumber, Carpenter, Painter, Blacksmith
- Vertical list of recommended craftsmen (from `getRecommendedCraftsmen`)
- Each card: name, rating, "View Profile" button → navigates to `CraftsmanProfileScreen` with `craftsmanId`

### Task 8 – Craftsman Profile Screen (`client/craftsman_profile_screen.dart`)
Receives `craftsmanId` via `ModalRoute.of(context)!.settings.arguments`.  
Displays:
- Cover image (placeholder), profile image, name, rating stars, total orders
- Skills → `Wrap` with `Chip`
- Portfolio → `GridView.builder`
- Reviews → `ListView.builder`
- Two buttons: "Request Service" (Gold), "Chat" (Dark Blue)

### Task 9 – Client My Orders Screen (`client/my_orders_screen.dart`)
- `DefaultTabController` with tabs: "Current" (`pending/accepted`) and "Previous" (`completed/cancelled`)
- Each tab: `ListView.builder` of orders from `getClientOrders`
- Order card shows: craftsman name, service description, status (color‑coded), price, date
- Conditional button: "Track" (for current) or "Cancel" (for pending)

### Task 10 – Chat Screen (`client/chat_screen.dart` & reused for craftsman)
Receives `orderId`, `craftsmanId`, `clientId`.  
- `StreamBuilder` listening to `getChatMessages`
- `ListView.builder` reversed (latest messages at bottom)
- Client messages: Gold light background (`#FCE4B2`), align right
- Craftsman messages: Grey background (`#E0E0E0`), align left
- Input field + send button → calls `sendChatMessage`
- Attach image icon → shows `SnackBar("Coming soon")`

### Task 11 – Client Profile Screen (`client/profile_screen.dart`)
- Show current user data (from `getCurrentUser`)
- Editable: name, phone number
- Update profile image button → opens `ImagePicker`
- Save button → updates Firestore `users` collection
- Logout button → calls `signOut()` → navigates to `LoginScreen`

### Task 12 – Craftsman Home Screen (`craftsman/home_screen.dart`)
- Summary cards: New orders count, In‑progress count, Completed count
- List of recent incoming orders (from `getCraftsmanOrders`) with Accept / Reject buttons
- Accept → `updateOrderStatus(orderId, 'accepted')`
- Reject → `updateOrderStatus(orderId, 'rejected')`

### Task 13 – Craftsman Profile Management (`craftsman/profile_screen.dart`)
- Edit personal info (name, phone, bio, yearsOfExperience)
- Manage skills: add (TextField + button), remove (X icon next to each skill)
- Portfolio: show images from `portfolioImages`, add new images (upload to Firebase Storage, then update Firestore)
- Location: TextField for city name
- Each section has its own Save button

### Task 14 – Craftsman Order Management (`craftsman/orders_screen.dart`)
- `TabBar`: New, In‑progress, Completed, Cancelled
- Each order shows: client name, service description, price, scheduled date
- Buttons depending on state:
  - New → Accept, Reject
  - In‑progress → Complete
  - Completed → nothing
  - Cancelled → nothing
- Calls `updateOrderStatus` accordingly

### Task 15 – Admin Dashboard (`admin/dashboard_screen.dart`)
- Stats cards: total users, total craftsmen, total orders, monthly revenue (from Firestore aggregations)
- Quick action buttons:
  - "Manage Users" → `AdminUsersScreen`
  - "Manage Orders" → `AdminOrdersScreen`
  - "Reports" → `AdminReportsScreen`
- Optional: `charts_flutter` for monthly order chart

### Task 16 – Admin User Management (`admin/users_screen.dart`)
- `TabBar`: Clients, Craftsmen, Registration Requests
- Each list: name, email, status (active/banned)
- Buttons: Activate/Deactivate, Delete
- Registration Requests: "Approve" or "Reject" for new craftsmen (set `isActive` = true/false)

### Task 17 – Admin Order Management (`admin/orders_screen.dart`)
- Filter by status (dropdown or chips)
- List all orders with: client name, craftsman name, service, price, status
- Buttons: "Resolve Dispute" (opens dialog), "Force Cancel" (changes status to `cancelled`)
- Manual status update dropdown (optional)

### Task 18 – Admin Reports & Analytics (`admin/reports_screen.dart`)
- Date range picker (`from` – `to`)
- Charts (use `fl_chart`):
  - Orders per day / month (bar chart)
  - Orders by category (pie chart)
- Top craftsmen: highest rated, most orders (two separate lists)
- Export to CSV button → shows `SnackBar("CSV export coming soon")`

### Task 19 – Final Routing & App Setup (`app.dart`, `main.dart`)
- `app.dart`:
  - `MaterialApp` with `theme` = `AppTheme.lightTheme` (Gold + Dark Blue from `constants.dart`)
  - `routes`: define named routes for **all** 15 screens
  - `initialRoute: '/login'`
  - `onGenerateRoute` to handle arguments (pass `craftsmanId`, `orderId`, etc.)
- `main.dart`:
  - `WidgetsFlutterBinding.ensureInitialized()`
  - `await Firebase.initializeApp()`
  - `runApp(const App())`

### Task 20 – Final Polish & Code Quality
- Every async operation must show `CircularProgressIndicator` while loading.
- Every error must show a red `SnackBar` with a user‑friendly message.
- Unify all colors: import `constants.dart`, never hard‑code `#C79A4D` or `#1B2A4A` inside screens.
- Ensure RTL support: `TextDirection.rtl` or `Directionality` for Arabic text.
- Run `flutter analyze` – fix all warnings.

---

## 7. Delivery Definition

- The AI agent will execute tasks **sequentially** (1 → 20).
- After each task, the agent must output:  
  `✅ Task X completed: [brief description]. Please test and confirm.`
- The agent **will not** push to GitHub. The user tests locally and pushes manually.
- Only after the user replies `Proceed to next task` the agent continues.

**The README is the single source of truth. No additional instructions are required.**
```