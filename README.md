# CampusCare – Campus Incident Reporting App

CampusCare is a Flutter mobile application that allows students to report problems around campus and helps authorized staff manage and resolve them.

The app makes it easier to report campus issues, track their progress, and keep students informed.

## Features

- **User Authentication:** Students can register, log in, and verify their email.
- **Incident Reporting:** Students can submit reports with a title, description, category, location, and optional photo.
- **Browse Reports:** Users can view submitted incidents.
- **Search and Filter:** Find reports by keywords or category.
- **Incident Details:** View information about each report and its current status.
- **Status Tracking:** Students can track whether an incident is Submitted, In Progress, or Resolved.
- **Staff Management:** Authorized staff can review reports and update their statuses.
- **Photo Upload:** Incident photos are uploaded using Cloudinary.

## Technologies Used

- Flutter and Dart – Mobile application development.
- Firebase Authentication – User registration and login.
- Cloud Firestore – Storing user profiles and incident reports.
- Provider – Application state management.
- Cloudinary – Incident photo storage.
- Image Picker – Selecting photos from the device.

## User Roles

**Student**
- Register and log in.
- Submit campus incident reports.
- Browse and track their reports.

**Staff**
- Access submitted incident reports.
- Review incident details.
- Update incident statuses.

Staff access is controlled through authorized user roles stored in Firestore.

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- A Firebase project
- A Cloudinary account configured for image uploads

### Installation

1. Clone the repository:

   ```bash
   https://github.com/Manzik1/campus_care
   ```

2. Open the project folder:

   ```bash
   cd campus_care
   ```

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Configure Firebase for your project and ensure the Firebase configuration files are available.

5. Configure your Cloudinary upload settings in the incident service.

6. Run the application:

   ```bash
   flutter run
   ```

## Data Storage

CampusCare uses Cloud Firestore to store:

- User profiles in the `users` collection.
- Campus incident reports in the `care_requests` collection.

Incident photos are stored in Cloudinary, and their image URLs are saved in Firestore.

**Note:** Cloudinary is used as the approved alternative to Firebase Storage for this assignment.

## Testing

Run the automated tests using:

```bash
flutter test
```

Check the project for code issues using:

```bash
flutter analyze
```

## Project Purpose

CampusCare was developed as an academic project to demonstrate mobile application development, Firebase integration, state management, user authentication, and role-based access control.

The goal is to improve how campus problems are reported, monitored, and resolved.

---
