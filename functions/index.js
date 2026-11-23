/**
 * LifeLink Firebase Cloud Functions & SMTP Email OTP Authentication Backend
 *
 * Implements:
 * 1. Allowed email domain enforcement (@gmail.com, @rku.ac.in).
 * 2. 6-digit cryptographically secure numeric OTP generation.
 * 3. Exact timing rules: 60 seconds validity, 30 seconds resend cooldown.
 * 4. Secure server-side hashing of OTPs in 'password_reset_tokens' collection.
 * 5. Production SMTP integration via Nodemailer using server secrets.
 * 6. Direct password update in Firebase Authentication using Firebase Admin SDK.
 * 7. Rate limiting & failed attempt protection.
 *
 * NOTE: Privileged administrative role management must be performed securely via
 * the Firebase CLI or an authorized server script, never via unauthenticated HTTP endpoints.
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const crypto = require("crypto");

admin.initializeApp();
const db = admin.firestore();

// ---------------------------------------------------------------------------
// CONFIGURATION & CONSTANTS
// ---------------------------------------------------------------------------
const ALLOWED_DOMAINS = ["gmail.com", "rku.ac.in"];
const OTP_VALIDITY_SECONDS = 60;
const RESEND_COOLDOWN_SECONDS = 30;
const MAX_FAILED_ATTEMPTS = 5;

/**
 * Retrieves the cryptographic salt for OTP hashing from environment variables or Firebase config.
 */
function getOtpSalt() {
  const salt =
    process.env.OTP_SALT ||
    (functions.config().security && functions.config().security.otp_salt);
  if (!salt) {
    throw new Error(
      "OTP_SALT environment variable or security.otp_salt config is not configured."
    );
  }
  return salt;
}

/**
 * Creates the configured Nodemailer SMTP transporter.
 * Credentials must be set via environment variables or Firebase config:
 *   firebase functions:config:set smtp.host="..." smtp.port="587" smtp.user="..." smtp.pass="..."
 */
function getSmtpTransporter() {
  const host =
    process.env.SMTP_HOST ||
    functions.config().smtp?.host ||
    "smtp.gmail.com";
  const port = parseInt(
    process.env.SMTP_PORT || functions.config().smtp?.port || "587",
    10
  );
  const user =
    process.env.SMTP_USER || functions.config().smtp?.user || "";
  const pass =
    process.env.SMTP_PASS || functions.config().smtp?.pass || "";

  if (!user || !pass) {
    throw new Error(
      "SMTP credentials not configured. Please set SMTP_USER and SMTP_PASS environment variables or Firebase config."
    );
  }

  return nodemailer.createTransporter({
    host: host,
    port: port,
    secure: port === 465,
    auth: {
      user: user,
      pass: pass,
    },
  });
}

/**
 * Normalizes email by trimming and lowercasing.
 */
function normalizeEmail(email) {
  return (email || "").trim().toLowerCase();
}

/**
 * Validates that an email belongs strictly to an allowed domain (@gmail.com, @rku.ac.in).
 */
function isAllowedDomain(email) {
  const normalized = normalizeEmail(email);
  const parts = normalized.split("@");
  if (parts.length !== 2) return false;
  return ALLOWED_DOMAINS.includes(parts[1]);
}

/**
 * Generates a safe document ID for password_reset_tokens by hashing the email.
 */
function getTokenDocId(email) {
  const normalized = normalizeEmail(email);
  return crypto
    .createHash("sha256")
    .update(`lifelink_token_${normalized}`)
    .digest("hex");
}

/**
 * Hashes the OTP using SHA-256 with the server salt and normalized email.
 */
function hashOtp(email, otp) {
  const normalized = normalizeEmail(email);
  const salt = getOtpSalt();
  return crypto
    .createHash("sha256")
    .update(`${salt}:${normalized}:${otp}`)
    .digest("hex");
}

// ---------------------------------------------------------------------------
// 1. SEND PASSWORD RESET OTP (HTTP Endpoint / Callable)
// ---------------------------------------------------------------------------
exports.sendPasswordResetOtp = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST") {
    res.status(405).json({ error: "Method Not Allowed" });
    return;
  }

  try {
    const { email } = req.body;
    const normalizedEmail = normalizeEmail(email);

    // 1. Email format and allowed domain validation
    if (!isAllowedDomain(normalizedEmail)) {
      res.status(400).json({
        success: false,
        error: "Only @gmail.com and @rku.ac.in emails are permitted.",
      });
      return;
    }

    const docId = getTokenDocId(normalizedEmail);
    const tokenRef = db.collection("password_reset_tokens").doc(docId);
    const existingDoc = await tokenRef.get();
    const now = admin.firestore.Timestamp.now();
    const nowMillis = now.toMillis();

    // 2. Enforce 30-second resend cooldown
    if (existingDoc.exists) {
      const data = existingDoc.data();
      const resendAvailableAt = data.resendAvailableAt;
      if (resendAvailableAt && nowMillis < resendAvailableAt.toMillis()) {
        const remainingSeconds = Math.ceil(
          (resendAvailableAt.toMillis() - nowMillis) / 1000
        );
        res.status(429).json({
          success: false,
          error: `Please wait ${remainingSeconds} second(s) before requesting another OTP.`,
          cooldownSeconds: remainingSeconds,
        });
        return;
      }
    }

    // 3. Generate cryptographically secure 6-digit numeric OTP
    const rawOtp = crypto.randomInt(100000, 1000000).toString();
    const otpHash = hashOtp(normalizedEmail, rawOtp);

    const expiresAt = admin.firestore.Timestamp.fromMillis(
      nowMillis + OTP_VALIDITY_SECONDS * 1000
    );
    const resendAvailableAt = admin.firestore.Timestamp.fromMillis(
      nowMillis + RESEND_COOLDOWN_SECONDS * 1000
    );

    // 4. Send email via Nodemailer SMTP
    const transporter = getSmtpTransporter();
    const fromAddress =
      process.env.SMTP_FROM ||
      functions.config().smtp?.from ||
      `"LifeLink Blood Network" <${process.env.SMTP_USER || "no-reply@lifelink.app"}>`;

    const mailOptions = {
      from: fromAddress,
      to: normalizedEmail,
      subject: "LifeLink - Password Recovery OTP",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 540px; margin: 0 auto; padding: 24px; border: 1px solid #E5E7EB; border-radius: 12px; background-color: #FFFFFF;">
          <div style="text-align: center; margin-bottom: 24px;">
            <h1 style="color: #0757D5; margin: 0; font-size: 28px; font-weight: 800;">LifeLink</h1>
            <p style="color: #6B7280; font-size: 14px; margin-top: 4px;">Blood Donation & Request Management</p>
          </div>
          <div style="background-color: #EFF6FF; border-radius: 8px; padding: 20px; text-align: center; margin-bottom: 24px;">
            <p style="color: #1E3A8A; font-size: 14px; margin-top: 0; font-weight: 600;">Your One-Time Password (OTP)</p>
            <div style="font-size: 36px; font-weight: 800; letter-spacing: 8px; color: #0757D5; margin: 12px 0;">
              ${rawOtp}
            </div>
            <p style="color: #B91C1C; font-size: 13px; font-weight: 700; margin-bottom: 0;">
              Valid for exactly ${OTP_VALIDITY_SECONDS} seconds.
            </p>
          </div>
          <p style="color: #4B5563; font-size: 14px; line-height: 1.5;">
            You requested to reset your password for your LifeLink account. Enter this 6-digit code in the app to complete your password reset.
          </p>
          <div style="margin-top: 24px; padding-top: 16px; border-top: 1px solid #E5E7EB; font-size: 12px; color: #9CA3AF;">
            <p style="margin: 0;"><strong>Security Notice:</strong> Never share this code with anyone. LifeLink staff will never ask for your recovery OTP. If you did not request this, please disregard this email.</p>
          </div>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);

    // 5. Store token metadata in Firestore (Invalidating any preceding OTP)
    await tokenRef.set({
      email: normalizedEmail,
      otpHash: otpHash,
      createdAt: now,
      expiresAt: expiresAt,
      resendAvailableAt: resendAvailableAt,
      failedAttempts: 0,
      usedAt: null,
    });

    res.status(200).json({
      success: true,
      message: `A 6-digit OTP has been dispatched to ${normalizedEmail}.`,
      validitySeconds: OTP_VALIDITY_SECONDS,
      cooldownSeconds: RESEND_COOLDOWN_SECONDS,
    });
  } catch (error) {
    console.error("Error in sendPasswordResetOtp:", error);
    res.status(500).json({
      success: false,
      error: error.message || "Internal server error occurred.",
    });
  }
});

// ---------------------------------------------------------------------------
// 2. VERIFY OTP AND RESET PASSWORD (HTTP Endpoint / Callable)
// ---------------------------------------------------------------------------
exports.verifyOtpAndResetPassword = functions.https.onRequest(
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ error: "Method Not Allowed" });
      return;
    }

    try {
      const { email, otp, newPassword } = req.body;
      const normalizedEmail = normalizeEmail(email);

      if (!isAllowedDomain(normalizedEmail)) {
        res.status(400).json({
          success: false,
          error: "Invalid email domain.",
        });
        return;
      }

      if (!otp || otp.toString().trim().length !== 6) {
        res.status(400).json({
          success: false,
          error: "A valid 6-digit OTP is required.",
        });
        return;
      }

      if (!newPassword || newPassword.length < 8) {
        res.status(400).json({
          success: false,
          error: "Password must be at least 8 characters.",
        });
        return;
      }

      const docId = getTokenDocId(normalizedEmail);
      const tokenRef = db.collection("password_reset_tokens").doc(docId);
      const tokenDoc = await tokenRef.get();

      if (!tokenDoc.exists) {
        res.status(404).json({
          success: false,
          error: "No active password recovery request found.",
        });
        return;
      }

      const data = tokenDoc.data();
      const now = admin.firestore.Timestamp.now();
      const nowMillis = now.toMillis();

      // 1. Check if token was already used
      if (data.usedAt) {
        res.status(400).json({
          success: false,
          error: "This OTP has already been used. Please request a new one.",
        });
        return;
      }

      // 2. Check rate limit on failed attempts
      if ((data.failedAttempts || 0) >= MAX_FAILED_ATTEMPTS) {
        res.status(403).json({
          success: false,
          error:
            "Too many failed verification attempts. This OTP has been invalidated.",
        });
        return;
      }

      // 3. Enforce 60-second validity expiration
      if (data.expiresAt && nowMillis > data.expiresAt.toMillis()) {
        res.status(400).json({
          success: false,
          error:
            "The OTP has expired (60s validity window elapsed). Please request a new OTP.",
        });
        return;
      }

      // 4. Validate OTP Hash
      const computedHash = hashOtp(normalizedEmail, otp.toString().trim());
      if (computedHash !== data.otpHash) {
        await tokenRef.update({
          failedAttempts: admin.firestore.FieldValue.increment(1),
        });
        const remaining = MAX_FAILED_ATTEMPTS - ((data.failedAttempts || 0) + 1);
        res.status(400).json({
          success: false,
          error: `Invalid OTP. ${remaining} attempt(s) remaining.`,
        });
        return;
      }

      // 5. Look up user by email in Firebase Authentication
      let userRecord;
      try {
        userRecord = await admin.auth().getUserByEmail(normalizedEmail);
      } catch (authError) {
        res.status(404).json({
          success: false,
          error: "No account found matching this email address.",
        });
        return;
      }

      // 6. Update user's password using Firebase Admin SDK
      await admin.auth().updateUser(userRecord.uid, {
        password: newPassword,
      });

      // 7. Revoke active refresh tokens for session security
      await admin.auth().revokeRefreshTokens(userRecord.uid);

      // 8. Consume token
      await tokenRef.update({
        usedAt: now,
      });

      res.status(200).json({
        success: true,
        message:
          "Password updated successfully in Firebase Authentication. You may now log in.",
      });
    } catch (error) {
      console.error("Error in verifyOtpAndResetPassword:", error);
      res.status(500).json({
        success: false,
        error: error.message || "Failed to reset password.",
      });
    }
  }
);
