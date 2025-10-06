# 🔐 Secure It - Flutter Password Holder App

This app is a **secure password holder** made with Flutter.  
It lets you **store, encrypt, and decrypt** your passwords locally on your device using AES-GCM encryption with PBKDF2 key derivation.  
Everything happens on your own device — **no cloud, no data tracking, no nonsense**.

**The biggest plus side is that this is an open-source project. Everyone can see what it is and what to do. What the fuck more do you want?**

---

## 🚀 Features

- AES-GCM encryption using `encrypt` and `pointycastle` packages  
- PBKDF2 key derivation with SHA-256  
- Random IV (Initialization Vector) for each encryption  
- Save passwords as encrypted `.txt` files in the app documents directory  
- Decrypt and read files with correct password + salt  
- Edit and rewrite encrypted entries  
- Simple, clean Material 3 UI  
- File management: add, read, edit, delete  

---

## 🧠 How It Works

1. You type:
   - A filename,
   - The content (your password or note),  
   - A password, 
   - A salt 

2. The app:
   - Generates a **PBKDF2 key** from your password and salt,  
   - Encrypts the content with **AES-GCM**,  
   - Combines IV + encrypted data and stores it as a base64 string in a `.txt` file  

3. When reading:
   - You enter the same password and salt,  
   - The app decrypts the file, 
   - You see your saved content

If the password or salt is wrong → it simply fails silently or shows an error message.

---

## 🧩 Packages Used

```yaml
dependencies:
  flutter:
    sdk: flutter
  encrypt: ^5.0.1
  pointycastle: ^3.7.3
  path_provider: ^2.1.1
```

---

## 🖱️ Usage
  - Tap the ➕ (Add) button to create a new encrypted password file.
  - Tap a file to decrypt it. (enter password + salt)
  - Tap the ✏️ edit icon to update an existing file. (after decrypting)
  - Tap the 🗑️ delete icon to remove it.

---

## 🔒 Notes
  - Make sure you remember your salt and password, otherwise your data cannot be recovered.
  - The app does not store or transmit any password or salt — everything is handled locally.
  - For stronger security, you can generate a random salt per file.

---

## 🧑‍💻 Author
  - Made by İhsan Demirci,
  - Just a developer who’s dumb as hell

---

## 🖼️ Screenshots
![IMG-20251007-WA0006](https://github.com/user-attachments/assets/3c3d7d85-5a11-4956-94d5-666b0d43bd95)
![IMG-20251007-WA0007](https://github.com/user-attachments/assets/bf387fd1-e776-43c6-89b3-5077c4ca6695)
![IMG-20251007-WA0003](https://github.com/user-attachments/assets/d307687a-67c9-4948-a3ff-522bf5486346)
![IMG-20251007-WA0002](https://github.com/user-attachments/assets/d8374473-4478-4ba0-859a-ee9680476bc1)
![IMG-20251007-WA0004](https://github.com/user-attachments/assets/9bb53e1b-cffd-4168-b6ef-3352fdeea81c)
![IMG-20251007-WA0005](https://github.com/user-attachments/assets/1c306894-204f-4aa0-bbdc-b0be6a52d6a5)

