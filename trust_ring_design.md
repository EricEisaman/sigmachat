# Proposal: Secure Ring of Trust Invitation System

**Objective:** Create a mechanism where new members are invited via a side channel completely unrelated to the application (SigmaChat). The system must be secure, covert, and establish a high degree of trust before the user even enters the chat network.

Here are 3 distinct approaches leveraging different "side channels":

---

## Option 1: The Steganographic "Dead Drop" (Covert Image Exchange)
**Concept**: The invitation is hidden inside a harmless-looking image (e.g., a meme, a landscape photo) using strict steganography.
**Side Channel**: Any public or private messaging platform (Signal, Email, Discord, or even a public forum post).

**Workflow:**
1.  **Inviter**: Generates a one-time cryptographic invitation token (signed with their private key).
2.  **Encoding**: The app embeds this token into an image selected by the Inviter. The visual appearance of the image is unchanged.
3.  **Transfer**: The Inviter sends this image to the Invitee via Signal, AirDrop, or email. "Check out this photo."
4.  **Invitee**: Saves the image to their device.
5.  **Onboarding**: The Invitee opens SigmaChat and selects "Join via Image". They pick the image.
6.  **Verification**: The app extracts the hidden data, verifies the Inviter's signature against the known "Ring of Trust" public keys, and grants access if valid.

**Pros:**
*   **Plausible Deniability**: The "invite" looks like a normal photo. Interceptors cannot easily prove it's a key.
*   **Platform Agnostic**: Can be sent over any medium that supports images without aggressive compression (though compression-resistant algos exist).
*   **User Friendly**: "Scanning a photo" is intuitive.

**Cons:**
*   **Compression**: Some platforms (like Facebook/WhatsApp) re-compress images, potentially destroying the data. Requires a file-transfer mode or specific platforms.

---

## Option 2: The Physical "Totem" (NFC/QR Air-Gap)
**Concept**: Trust can only be established through physical proximity. The "side channel" is the physical space between two devices.
**Side Channel**: Physical Atoms (Hardware).

**Workflow:**
1.  **Meeting**: The Inviter and Invitee must meet in person.
2.  **Inviter**: Opens the "Issue Trust" interface. This generates a high-entropy key pair for the new user.
3.  **Transfer (NFC)**: The Inviter taps their phone to the Invitee's phone (or a blank NFC tag/card).
4.  **Transfer (QR)**: Alternatively, the Inviter's screen flashes a rapid sequence of QR codes (to transmit a large key payload offline).
5.  **Onboarding**: The Invitee's app captures this payload. It contains the server address, the channel encryption keys, and their own signed identity.
6.  **No Internet**: This entire handshake happens offline.

**Pros:**
*   **Maximum Security**: Impossible to intercept remotely. MITM attacks are impossible without physical presence.
*   **Sybil Proof**: Hard to mass-generate fake accounts if you have to physically meet every person.

**Cons:**
*   **Scalability**: Requires physical presence. Cannot invite someone in another country.

---

## Option 3: The "Book Code" (Cognitive/Shared Knowledge)
**Concept**: The invitation key is derived from a shared piece of knowledge or a physical book that both parties possess, combined with a short ephemeral code.
**Side Channel**: A physical book, a specific document, or a long-form text known to the group.

**Workflow:**
1.  **Setup**: The Ring of Trust agrees on a "Source Text" (e.g., *The hitchhiker's guide to the galaxy*, Page 42, 3rd paragraph, or a specific PDF manually distributed).
2.  **Inviter**: Tells the Invitee (via phone call or secure chat): "Use the code: 5-8-2-1".
3.  **Derivation**: The "code" represents specific words/characters in the Source Text (Line 5, Word 8...).
4.  **Hashing**: The app takes those specific words from the local copy of the Source Text and hashes them to generate the decryption key for the invite payload.
5.  **Onboarding**: The Invitee enters "5-8-2-1" in the app. The app references the stored Source Text, derives the key, and unlocks the entrance.

**Pros:**
*   **Obscurity**: The code "5-8-2-1" is meaningless without the Source Text. Even if intercepted, it's useless.
*   **Remote Capable**: Can be done over a voice call or encrypted chat.
*   **Cool Factor**: High "spy craft" feel (One-Time Pad style).

**Cons:**
*   **Complexity**: Users must have the exact same edition/version of the Source Text installed or available.
*   **Human Error**: Prone to typos or counting errors.

---

### Recommendation
**Option 1 (Steganography)** is the most robust balance of security, usability, and "cool factor" for a digital product. It allows for remote invites while maintaining plausible deniability.
