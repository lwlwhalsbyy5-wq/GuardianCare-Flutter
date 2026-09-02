CREATE DATABASE IF NOT EXISTS `guardiancare`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `guardiancare`;

-- ── users ─────────────────────────────────────────────────────
-- user_id = normalizeUserId() output (trimmed, lowercase email)
-- Matches: LinkedUserProfile, AppUserContext, registerUser()
CREATE TABLE IF NOT EXISTS `users` (
  `user_id`       VARCHAR(254) NOT NULL PRIMARY KEY,
  `name`          VARCHAR(150) NOT NULL,
  `email`         VARCHAR(254) NOT NULL,
  `password_hash` VARCHAR(255) DEFAULT NULL,
  `role`          ENUM('patient', 'caregiver') NOT NULL DEFAULT 'patient',
  `created_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_users_email` (`email`),
  INDEX `idx_users_role`  (`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── patient_caregiver_links ────────────────────────────────────
-- Mirrors: _patientToCaregivers / _caregiverToPatients maps
-- Matches: linkPatientAndCaregiver(), linkedCaregiversForPatient(),
--          linkedPatientsForCaregiver()
CREATE TABLE IF NOT EXISTS `patient_caregiver_links` (
  `id`                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `patient_user_id`   VARCHAR(254) NOT NULL,
  `caregiver_user_id` VARCHAR(254) NOT NULL,
  `created_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`patient_user_id`)   REFERENCES `users`(`user_id`) ON DELETE CASCADE,
  FOREIGN KEY (`caregiver_user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE,
  UNIQUE KEY `uq_link` (`patient_user_id`, `caregiver_user_id`),
  INDEX `idx_link_patient`   (`patient_user_id`),
  INDEX `idx_link_caregiver` (`caregiver_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── medications ────────────────────────────────────────────────
-- Mirrors: MedicationRecord { name, schedule, taken }
-- schedule values match _habitOptions in MedicationEntryPage
CREATE TABLE IF NOT EXISTS `medications` (
  `id`              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `patient_user_id` VARCHAR(254) NOT NULL,
  `name`            VARCHAR(200) NOT NULL,
  `schedule`        ENUM('After Breakfast','After Lunch','After Dinner') NOT NULL,
  `taken`           TINYINT(1) NOT NULL DEFAULT 0,
  `created_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`patient_user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE,
  INDEX `idx_meds_patient` (`patient_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── dose_reminders ─────────────────────────────────────────────
-- Mirrors: _DoseReminder { medicationName, schedule, isResolved }
-- missedDosesForUser() returns rows where is_resolved = 0
CREATE TABLE IF NOT EXISTS `dose_reminders` (
  `id`              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id`         VARCHAR(254) NOT NULL,
  `medication_name` VARCHAR(200) NOT NULL,
  `schedule`        ENUM('After Breakfast','After Lunch','After Dinner') NOT NULL,
  `is_resolved`     TINYINT(1) NOT NULL DEFAULT 0,
  `created_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE,
  INDEX `idx_reminders_user`     (`user_id`),
  INDEX `idx_reminders_resolved` (`user_id`, `is_resolved`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── notifications ──────────────────────────────────────────────
-- Mirrors: _notificationsByUser, notificationsForUser()
-- Most recent first (mirrors .insert(0, message) in Dart)
CREATE TABLE IF NOT EXISTS `notifications` (
  `id`         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id`    VARCHAR(254) NOT NULL,
  `message`    TEXT NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE,
  INDEX `idx_notif_user` (`user_id`),
  INDEX `idx_notif_time` (`user_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── Seed Data ──────────────────────────────────────────────────
-- password for both accounts is: password
INSERT IGNORE INTO `users` (`user_id`,`name`,`email`,`password_hash`,`role`) VALUES
  ('alice@patient.local','Alice','alice@patient.local',
   '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi','patient'),
  ('bob@caregiver.local','Bob','bob@caregiver.local',
   '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi','caregiver');

INSERT IGNORE INTO `patient_caregiver_links`
  (`patient_user_id`,`caregiver_user_id`) VALUES
  ('alice@patient.local','bob@caregiver.local');

INSERT IGNORE INTO `medications`
  (`patient_user_id`,`name`,`schedule`,`taken`) VALUES
  ('alice@patient.local','Aspirin 100mg','After Breakfast',0),
  ('alice@patient.local','Vitamin D3','After Lunch',1);

INSERT IGNORE INTO `dose_reminders`
  (`user_id`,`medication_name`,`schedule`,`is_resolved`) VALUES
  ('alice@patient.local','Aspirin 100mg','After Breakfast',0),
  ('alice@patient.local','Vitamin D3','After Lunch',1),
  ('bob@caregiver.local','Aspirin 100mg','After Breakfast',0),
  ('bob@caregiver.local','Vitamin D3','After Lunch',1);

INSERT IGNORE INTO `notifications` (`user_id`,`message`) VALUES
  ('alice@patient.local','Caregiver Bob linked to your account.'),
  ('alice@patient.local','Medication "Aspirin 100mg" scheduled: After Breakfast.'),
  ('alice@patient.local','Medication "Vitamin D3" scheduled: After Lunch.'),
  ('alice@patient.local','Dose marked as taken: Vitamin D3 (After Lunch).'),
  ('bob@caregiver.local','Patient Alice linked to your account.'),
  ('bob@caregiver.local','Patient medication "Aspirin 100mg" scheduled: After Breakfast.'),
  ('bob@caregiver.local','Patient medication "Vitamin D3" scheduled: After Lunch.'),
  ('bob@caregiver.local','Dose marked as taken: Vitamin D3 (After Lunch).');