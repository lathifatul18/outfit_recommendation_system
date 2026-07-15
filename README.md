# 👕 Outfit Recommendation System

A fashion outfit recommendation system that generates personalized outfit combinations based on the visual similarity of uploaded clothing images. The system leverages **Transfer Learning (ResNet50)** for feature extraction, **Cosine Similarity** for visual similarity measurement, and **Rule-Based Recommendation** to generate complete outfit combinations.

This project consists of two main components:

- 📱 **Frontend** – Flutter Mobile Application
- ⚙️ **Backend** – Flask REST API with MySQL Database

---

## 📖 Project Overview

The application enables users to upload a fashion item image and receive outfit recommendations generated from a fashion dataset. Recommendations are produced by extracting visual features from the uploaded image, comparing them with stored dataset embeddings, and combining the most similar items into a complete outfit.

---

# ✨ Features

### 👤 User Features

- User Registration
- User Login
- Upload Fashion Image
- Outfit Recommendation
- View Outfit Details
- Save Favorite Outfit
- Manage Favorite List
- User Profile

### 🤖 Recommendation Features

- Image Preprocessing
- Feature Extraction using ResNet50
- Visual Similarity Search
- Rule-Based Outfit Combination
- REST API Integration

---

# 🛠️ Tech Stack

## Frontend

- Flutter
- Dart
- Provider
- Dio
- Shared Preferences
- Image Picker

## Backend

- Flask
- SQLAlchemy
- MySQL
- TensorFlow / Keras
- NumPy
- Scikit-learn

---

# 🏗️ System Architecture

```
                    User
                      │
                      ▼
           Flutter Mobile Application
                      │
              REST API (HTTP)
                      │
                      ▼
                Flask Backend
                      │
      ┌───────────────┼────────────────┐
      │               │                │
      ▼               ▼                ▼
 Authentication   Recommendation   MySQL Database
                      │
                      ▼
            Image Preprocessing
                      │
                      ▼
        ResNet50 Feature Extraction
                      │
                      ▼
            Cosine Similarity
                      │
                      ▼
       Rule-Based Recommendation
                      │
                      ▼
              Recommendation Result
                      │
                      ▼
              Flutter Application
```

---

# 🔄 Recommendation Workflow

1. User uploads a clothing image from the Flutter application.
2. The image is sent to the Flask backend through REST API.
3. Backend preprocesses the uploaded image.
4. ResNet50 extracts visual features (embeddings).
5. The embedding is compared with dataset embeddings using Cosine Similarity.
6. The most visually similar fashion item is identified.
7. Rule-Based Recommendation generates a complete outfit combination.
8. Recommendation results are returned as JSON.
9. Flutter displays the recommended outfit.

---

# 📂 Project Structure

```
outfit_recommendation_system/
│
├── frontend/
│   ├── lib/
│   ├── assets/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
├── backend/
│   ├── app.py
│   ├── models/
│   ├── routes/
│   ├── services/
│   ├── scripts/
│   ├── uploads/
│   └── requirements.txt
│
└── README.md
```

---

# 🚀 Getting Started

## Clone Repository

```bash
git clone https://github.com/lathifatul18/outfit_recommendation_system.git
cd outfit_recommendation_system
```

---

## Backend Setup

```bash
cd backend
```

Create virtual environment.

```bash
python -m venv venv
```

Activate virtual environment.

Windows

```bash
venv\Scripts\activate
```

Linux / macOS

```bash
source venv/bin/activate
```

Install dependencies.

```bash
pip install -r requirements.txt
```

Run Flask server.

```bash
python app.py
```

---

## Frontend Setup

```bash
cd frontend
```

Install packages.

```bash
flutter pub get
```

Configure the backend API URL.

Run the application.

```bash
flutter run
```

---

# 📡 API Communication

The Flutter application communicates with the Flask backend using REST API for:

- Authentication
- Image Upload
- Outfit Recommendation
- Favorite Management
- User Profile

---

# 📸 Screenshots

> Add screenshots of your application here.

- Splash Screen
- Login
- Home
- Upload
- Recommendation
- Favorite
- Profile

---

# 🎓 Capstone Project

**Title**

> Sistem Rekomendasi Outfit Fashion Berbasis Kemiripan Visual Menggunakan Transfer Learning

### Recommendation Methods

- Transfer Learning (ResNet50)
- Feature Extraction
- Cosine Similarity
- Rule-Based Recommendation

---

# 👩‍💻 Author

**Lathifatul Maulyda**

Bachelor of Applied Software Engineering Technology

Politeknik Negeri Padang

GitHub: https://github.com/lathifatul18

---

# 📄 License

This project was developed for educational and research purposes as part of a Capstone Project.