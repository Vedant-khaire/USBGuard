# USBGuard   
**Real-Time Detection & Logging of Malicious USB Devices**

USBGuard is a cross-platform **Flutter-based desktop application** designed to monitor USB devices in real time, detect suspicious activities, and maintain detailed logs to help users stay protected from USB-based threats.

This project focuses on **defensive cybersecurity** and is built as an academic and practical security solution.

---

# Features

-  **Real-time USB device detection**
-  **Suspicious file scanning**
  - Detects `.bat`, `.ps1`, `autorun.inf`, hidden `.exe` files
-  **Local activity logging**
-  **Export logs to CSV**
-  **Clean & modern Flutter UI**
-  **Dark / Light mode support**
-  **Windows desktop support (Installer available)**

---

# Project Objective

USB-based attacks are a common yet often ignored threat vector.  
USBGuard aims to:
- Monitor USB plug-in events
- Analyze USB contents for malicious indicators
- Log activities for forensic and security analysis
- Provide a simple and user-friendly security tool

---

# Tech Stack

- **Frontend:** Flutter (Dart)
- **Platform:** Windows Desktop
- **Database:** Local storage (SQLite)
- **Installer:** Inno Setup
- **Architecture:** Modular service-based design

---

# Installation (Windows)

1. Go to **Releases** section of this repository
2. Download `USBGuard_Installer.exe`
3. Run the installer
4. Launch USBGuard from the Start Menu

>  No Flutter SDK or developer tools required.

---

# Project Structure (Simplified)

lib/
├── services/ # USB detection, scanning, logging
├── models/ # Data models
├── ui/ # Screens & UI components
├── utils/ # Helpers & exports


---

# Academic Context

This project is developed as part of a **Cybersecurity / Forensics academic project**, focusing on:
- Endpoint security
- USB attack detection
- Defensive security practices

---

# Future Enhancements

- USB auto-blocking with user confirmation
- Signature-based malware detection
- SIEM integration
- Linux & Android support
- Alert notifications

---

# Author

**Vedant Sopan Khaire**  
Cyber Security & Forensics Student  
GitHub: https://github.com/Vedant-khaire

---

# License

This project is intended for **educational and research purposes**.


## 📁 Project Structure (Simplified)

