<?php
require_once __DIR__ . '/db_connect.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

// ── JWT ───────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════
//  caregiver_patient_meds
//
//  Lets a caregiver fetch a specific linked patient's full
//  medication list (name, schedule, taken status) in one call.
//
//  Safety check: the caregiver must be linked to that patient
//  in patient_caregiver_links — they cannot query strangers.
//
//  GET ?action=caregiver_patient_meds
//      &caregiver_user_id=bob@caregiver.local
//      &patient_user_id=alice@patient.local
//
//  Response:
//  {
//    "success": true,
//    "patient": { "user_id": "alice@patient.local", "name": "Alice", "email": "alice@patient.local" },
//    "medications": [
//      { "id": 1, "name": "Aspirin 100mg", "schedule": "After Breakfast", "taken": false },
//      { "id": 2, "name": "Vitamin D3",    "schedule": "After Lunch",     "taken": true  }
//    ],
//    "summary": {
//      "total": 2,
//      "taken": 1,
//      "missed": 1,
//      "adherence_pct": 50
//    }
//  }
// ══════════════════════════════════════════════════════════════
function handleCaregiverPatientMeds(): never {
    $caregiverId = normalizeUserId($_GET['caregiver_user_id'] ?? '');
    $patientId   = normalizeUserId($_GET['patient_user_id']   ?? '');

    if (!$caregiverId) sendError('caregiver_user_id is required');
    if (!$patientId)   sendError('patient_user_id is required');

    $db = getConnection();

    // ── Safety check: caregiver must be linked to this patient ──
    // Mirrors the fact that linkedPatientsForCaregiver() only returns
    // patients in _caregiverToPatients[caregiverId].
    $linkCheck = $db->prepare(
        'SELECT id FROM patient_caregiver_links
         WHERE caregiver_user_id = ? AND patient_user_id = ?
         LIMIT 1'
    );
    $linkCheck->execute([$caregiverId, $patientId]);
    if (!$linkCheck->fetch()) {
        sendError('This caregiver is not linked to the specified patient', 403);
    }

    // ── Fetch patient profile (LinkedUserProfile fields) ────────
    $patientStmt = $db->prepare(
        'SELECT user_id, name, email FROM users WHERE user_id = ?'
    );
    $patientStmt->execute([$patientId]);
    $patient = $patientStmt->fetch();
    if (!$patient) sendError('Patient not found', 404);

    // ── Fetch medications (MedicationRecord fields) ──────────────
    // Returns: id, name, schedule, taken — matching MedicationRecord
    $medStmt = $db->prepare(
        'SELECT id, name, schedule, (taken = 1) AS taken
         FROM medications
         WHERE patient_user_id = ?
         ORDER BY created_at ASC'
    );
    $medStmt->execute([$patientId]);
    $medications = $medStmt->fetchAll();

    // Cast taken to bool to match MedicationRecord.taken (Dart bool)
    foreach ($medications as &$med) {
        $med['taken'] = (bool) $med['taken'];
    }
    unset($med);

    // ── Build adherence summary ──────────────────────────────────
    $total  = count($medications);
    $taken  = count(array_filter($medications, fn($m) => $m['taken'] === true));
    $missed = $total - $taken;
    $adherencePct = $total > 0 ? (int) round($taken / $total * 100) : 0;

    sendJson([
        'success'     => true,
        'patient'     => $patient,
        'medications' => $medications,
        'summary'     => [
            'total'          => $total,
            'taken'          => $taken,
            'missed'         => $missed,
            'adherence_pct'  => $adherencePct,
        ],
    ]);
}
function jwtEncode(array $payload): string {
    $h = b64url(json_encode(['alg'=>'HS256','typ'=>'JWT']));
    $p = b64url(json_encode($payload));
    $s = b64url(hash_hmac('sha256',"$h.$p",JWT_SECRET,true));
    return "$h.$p.$s";
}
function jwtDecode(string $token): ?array {
    $parts = explode('.',$token);
    if (count($parts)!==3) return null;
    [$h,$p,$s]=$parts;
    if (!hash_equals(b64url(hash_hmac('sha256',"$h.$p",JWT_SECRET,true)),$s)) return null;
    $data=json_decode(base64_decode(strtr($p,'-_','+/')),true);
    if (!is_array($data)) return null;
    if (isset($data['exp'])&&$data['exp']<time()) return null;
    return $data;
}
function b64url(string $d): string { return rtrim(strtr(base64_encode($d),'+/','-_'),'='); }

// ── Helpers ───────────────────────────────────────────────────
function normalizeUserId(string $v): string { return strtolower(trim($v)); }
function body(): array {
    static $b=null;
    if ($b===null) $b=json_decode(file_get_contents('php://input'),true)??[];
    return $b;
}
function sendJson(mixed $d, int $c=200): never {
    http_response_code($c);
    echo json_encode($d,JSON_UNESCAPED_UNICODE);
    exit;
}
function sendError(string $m, int $c=400): never { sendJson(['success'=>false,'message'=>$m],$c); }

// ── Router ────────────────────────────────────────────────────
$action = $_GET['action'] ?? '';
match(true) {
    $action==='register'             => handleRegister(),
    $action==='login'                => handleLogin(),
    $action==='register_user'        => handleRegisterUser(),
    $action==='link'                 => handleLink(),
    $action==='linked_caregivers'    => handleLinkedCaregivers(),
    $action==='linked_patients'      => handleLinkedPatients(),
    $action==='medications'          => handleMedications(),
    $action==='add_medication'       => handleAddMedication(),
    $action==='set_medication_taken' => handleSetMedicationTaken(),
    $action==='notifications'        => handleNotifications(),
    $action==='missed_doses'         => handleMissedDoses(),
    $action==='missed_doses'         => handleMissedDoses(),
$action==='caregiver_patient_meds' => handleCaregiverPatientMeds(),  // ← ADD THIS
    default                          => sendError("Unknown action: '$action'",404),
};

// ── register ──────────────────────────────────────────────────
function handleRegister(): never {
    if ($_SERVER['REQUEST_METHOD']!=='POST') sendError('POST required',405);
    $b=body();
    $name=trim($b['name']??'');
    $email=normalizeUserId($b['email']??'');
    $password=$b['password']??'';
    $role=$b['role']??'patient';
    if (!$name) sendError('name is required');
    if (!$email||!str_contains($email,'@')) sendError('valid email required');
    if (strlen($password)<8) sendError('password must be at least 8 characters');
    if (!in_array($role,['patient','caregiver'])) sendError('invalid role');
    $db=getConnection();
    $s=$db->prepare('SELECT user_id FROM users WHERE user_id=?');
    $s->execute([$email]);
    if ($s->fetch()) sendError('Email already registered',409);
    $db->prepare('INSERT INTO users (user_id,name,email,password_hash,role) VALUES (?,?,?,?,?)')
       ->execute([$email,$name,$email,password_hash($password,PASSWORD_BCRYPT),$role]);
    $token=jwtEncode(['sub'=>$email,'role'=>$role,'exp'=>time()+JWT_TTL]);
    sendJson(['success'=>true,'token'=>$token,
              'user'=>['user_id'=>$email,'name'=>$name,'email'=>$email,'role'=>$role]],201);
}

// ── login ─────────────────────────────────────────────────────
function handleLogin(): never {
    if ($_SERVER['REQUEST_METHOD']!=='POST') sendError('POST required',405);
    $b=body();
    $email=normalizeUserId($b['email']??'');
    $password=$b['password']??'';
    if (!$email||!$password) sendError('email and password required');
    $db=getConnection();
    $s=$db->prepare('SELECT * FROM users WHERE user_id=?');
    $s->execute([$email]);
    $user=$s->fetch();
    if (!$user||!$user['password_hash']||!password_verify($password,$user['password_hash']))
        sendError('Invalid credentials',401);
    $token=jwtEncode(['sub'=>$user['user_id'],'role'=>$user['role'],'exp'=>time()+JWT_TTL]);
    sendJson(['success'=>true,'token'=>$token,
              'user'=>['user_id'=>$user['user_id'],'name'=>$user['name'],
                       'email'=>$user['email'],'role'=>$user['role']]]);
}

// ── register_user — mirrors GuardianCareRepository.registerUser() ──
function handleRegisterUser(): never {
    if ($_SERVER['REQUEST_METHOD']!=='POST') sendError('POST required',405);
    $b=body();
    $userId=normalizeUserId($b['user_id']??'');
    $name=trim($b['name']??'');
    $email=normalizeUserId($b['email']??'');
    $role=$b['role']??'patient';
    if (!$userId) sendError('user_id required');
    if (!$email)  sendError('email required');
    if (!in_array($role,['patient','caregiver'])) sendError('invalid role');
    $displayName=$name!==''?$name:$email;
    $db=getConnection();
    $db->prepare(
        'INSERT INTO users (user_id,name,email,role) VALUES (?,?,?,?)
         ON DUPLICATE KEY UPDATE
           name =IF(name <>VALUES(name), VALUES(name), name),
           email=IF(email<>VALUES(email),VALUES(email),email)'
    )->execute([$userId,$displayName,$email,$role]);
    $s=$db->prepare('SELECT user_id,name,email,role FROM users WHERE user_id=?');
    $s->execute([$userId]);
    sendJson(['success'=>true,'user'=>$s->fetch()]);
}

// ══════════════════════════════════════════════════════════════
//  link — mirrors GuardianCareRepository.linkPatientAndCaregiver()
//
//  Called from CaregiverManagementPage._addPatient() in both directions:
//    Caregiver adds patient  →  isPatientManagingCaregivers = false
//    Patient adds caregiver  →  isPatientManagingCaregivers = true
//
//  POST body: {
//    patient_user_id,  patient_name,  patient_email,
//    caregiver_name,   caregiver_email
//  }
//
//  Mirrors GuardianCareStore.linkPatientAndCaregiver() exactly:
//    1. _upsertByEmail(patient)
//    2. _upsertByEmail(caregiver)
//    3. _patientToCaregivers[patientId].add(caregiverId)   ← UNIQUE KEY
//    4. _caregiverToPatients[caregiverId].add(patientId)   ← same row
//    5. _addNotification(patientId, "Caregiver X linked…")
//    6. _addNotification(caregiverId,"Patient Y linked…")
// ══════════════════════════════════════════════════════════════
function handleLink(): never {
    if ($_SERVER['REQUEST_METHOD']!=='POST') sendError('POST required',405);
    $b=body();
    $patientUserId  = normalizeUserId($b['patient_user_id']  ?? '');
    $patientName    = trim($b['patient_name']   ?? '');
    $patientEmail   = normalizeUserId($b['patient_email']    ?? '');
    $caregiverName  = trim($b['caregiver_name'] ?? '');
    $caregiverEmail = normalizeUserId($b['caregiver_email']  ?? '');

    if (!$patientEmail)   sendError('patient_email is required');
    if (!$caregiverEmail) sendError('caregiver_email is required');

    $db=getConnection();

    // Step 1 — upsert patient (mirrors _upsertByEmail)
    $pName = $patientName!=='' ? $patientName : $patientEmail;
    $db->prepare(
        'INSERT INTO users (user_id,name,email,role) VALUES (?,?,?,"patient")
         ON DUPLICATE KEY UPDATE name=VALUES(name),email=VALUES(email)'
    )->execute([$patientEmail,$pName,$patientEmail]);

    // Step 2 — upsert caregiver (mirrors _upsertByEmail)
    $cName = $caregiverName!=='' ? $caregiverName : $caregiverEmail;
    $db->prepare(
        'INSERT INTO users (user_id,name,email,role) VALUES (?,?,?,"caregiver")
         ON DUPLICATE KEY UPDATE name=VALUES(name),email=VALUES(email)'
    )->execute([$caregiverEmail,$cName,$caregiverEmail]);

    // Steps 3+4 — insert link row; IGNORE = idempotent, mirrors Set.add()
    $db->prepare(
        'INSERT IGNORE INTO patient_caregiver_links
         (patient_user_id,caregiver_user_id) VALUES (?,?)'
    )->execute([$patientEmail,$caregiverEmail]);

    // Step 5 — notification for patient
    $db->prepare('INSERT INTO notifications (user_id,message) VALUES (?,?)')
       ->execute([$patientEmail,"Caregiver $cName linked to your account."]);

    // Step 6 — notification for caregiver
    $db->prepare('INSERT INTO notifications (user_id,message) VALUES (?,?)')
       ->execute([$caregiverEmail,"Patient $pName linked to your account."]);

    sendJson(['success'=>true,'message'=>'Linked successfully'],201);
}

// ── linked_caregivers — mirrors linkedCaregiversForPatient() ──
function handleLinkedCaregivers(): never {
    $id=normalizeUserId($_GET['patient_user_id']??'');
    if (!$id) sendError('patient_user_id required');
    $db=getConnection();
    $s=$db->prepare(
        'SELECT u.user_id AS id,u.name,u.email
         FROM patient_caregiver_links l
         JOIN users u ON u.user_id=l.caregiver_user_id
         WHERE l.patient_user_id=? ORDER BY l.created_at ASC');
    $s->execute([$id]);
    sendJson(['success'=>true,'data'=>$s->fetchAll()]);
}

// ── linked_patients — mirrors linkedPatientsForCaregiver() ────
function handleLinkedPatients(): never {
    $id=normalizeUserId($_GET['caregiver_user_id']??'');
    if (!$id) sendError('caregiver_user_id required');
    $db=getConnection();
    $s=$db->prepare(
        'SELECT u.user_id AS id,u.name,u.email
         FROM patient_caregiver_links l
         JOIN users u ON u.user_id=l.patient_user_id
         WHERE l.caregiver_user_id=? ORDER BY l.created_at ASC');
    $s->execute([$id]);
    sendJson(['success'=>true,'data'=>$s->fetchAll()]);
}

// ── medications — mirrors medicationsForPatient() ─────────────
function handleMedications(): never {
    $id=normalizeUserId($_GET['patient_user_id']??'');
    if (!$id) sendError('patient_user_id required');
    $db=getConnection();
    $s=$db->prepare(
        'SELECT id,name,schedule,(taken=1) AS taken FROM medications
         WHERE patient_user_id=? ORDER BY created_at ASC');
    $s->execute([$id]);
    $rows=$s->fetchAll();
    foreach ($rows as &$r) $r['taken']=(bool)$r['taken'];
    sendJson(['success'=>true,'data'=>$rows]);
}

// ── add_medication — mirrors addMedication() ──────────────────
function handleAddMedication(): never {
    if ($_SERVER['REQUEST_METHOD']!=='POST') sendError('POST required',405);
    $b=body();
    $patientId=normalizeUserId($b['patient_user_id']??'');
    $name=trim($b['medication_name']??'');
    $schedule=$b['schedule']??'';
    if (!$patientId) sendError('patient_user_id required');
    if (!$name)      sendError('medication_name required');
    $valid=['After Breakfast','After Lunch','After Dinner'];
    if (!in_array($schedule,$valid,true))
        sendError('schedule must be: '.implode(', ',$valid));
    $db=getConnection();
    $db->prepare(
        'INSERT INTO medications (patient_user_id,name,schedule,taken) VALUES (?,?,?,0)'
    )->execute([$patientId,$name,$schedule]);
    // notification + reminder for patient
    $db->prepare('INSERT INTO notifications (user_id,message) VALUES (?,?)')
       ->execute([$patientId,"Medication \"$name\" scheduled: $schedule."]);
    $db->prepare(
        'INSERT INTO dose_reminders (user_id,medication_name,schedule,is_resolved) VALUES (?,?,?,0)'
    )->execute([$patientId,$name,$schedule]);
    // propagate to linked caregivers
    $cgs=$db->prepare(
        'SELECT u.user_id FROM patient_caregiver_links l
         JOIN users u ON u.user_id=l.caregiver_user_id
         WHERE l.patient_user_id=?');
    $cgs->execute([$patientId]);
    foreach ($cgs->fetchAll() as $cg) {
        $db->prepare('INSERT INTO notifications (user_id,message) VALUES (?,?)')
           ->execute([$cg['user_id'],"Patient medication \"$name\" scheduled: $schedule."]);
        $db->prepare(
            'INSERT INTO dose_reminders (user_id,medication_name,schedule,is_resolved) VALUES (?,?,?,0)'
        )->execute([$cg['user_id'],$name,$schedule]);
    }
    sendJson(['success'=>true,'message'=>'Medication added'],201);
}

// ── set_medication_taken — mirrors setMedicationTaken() ───────
function handleSetMedicationTaken(): never {
    if ($_SERVER['REQUEST_METHOD']!=='POST') sendError('POST required',405);
    $b=body();
    $patientId=normalizeUserId($b['patient_user_id']??'');
    $name=trim($b['medication_name']??'');
    $schedule=$b['schedule']??'';
    $taken=filter_var($b['taken']??false,FILTER_VALIDATE_BOOLEAN,FILTER_NULL_ON_FAILURE);
    if (!$patientId) sendError('patient_user_id required');
    if (!$name)      sendError('medication_name required');
    if ($taken===null) sendError('taken must be true or false');
    $db=getConnection();
    $db->prepare(
        'UPDATE medications SET taken=? WHERE patient_user_id=? AND name=? AND schedule=?'
    )->execute([(int)$taken,$patientId,$name,$schedule]);
    $cgs=$db->prepare(
        'SELECT caregiver_user_id AS user_id FROM patient_caregiver_links WHERE patient_user_id=?');
    $cgs->execute([$patientId]);
    $recipients=array_unique([$patientId,...array_column($cgs->fetchAll(),'user_id')]);
    foreach ($recipients as $uid) {
        $db->prepare(
            'UPDATE dose_reminders SET is_resolved=?
             WHERE user_id=? AND medication_name=? AND schedule=?'
        )->execute([(int)$taken,$uid,$name,$schedule]);
        if ($taken) {
            $db->prepare('INSERT INTO notifications (user_id,message) VALUES (?,?)')
               ->execute([$uid,"Dose marked as taken: $name ($schedule)."]);
        }
    }
    sendJson(['success'=>true,'taken'=>$taken]);
}

// ── notifications — mirrors notificationsForUser() ────────────
function handleNotifications(): never {
    $id=normalizeUserId($_GET['user_id']??'');
    if (!$id) sendError('user_id required');
    $db=getConnection();
    $s=$db->prepare(
        'SELECT message FROM notifications
         WHERE user_id=? ORDER BY created_at DESC,id DESC LIMIT 100');
    $s->execute([$id]);
    sendJson(['success'=>true,'data'=>array_column($s->fetchAll(),'message')]);
}

// ── missed_doses — mirrors missedDosesForUser() ───────────────
function handleMissedDoses(): never {
    $id=normalizeUserId($_GET['user_id']??'');
    if (!$id) sendError('user_id required');
    $db=getConnection();
    $s=$db->prepare(
        'SELECT medication_name,schedule FROM dose_reminders
         WHERE user_id=? AND is_resolved=0 ORDER BY created_at ASC');
    $s->execute([$id]);
    $rows=$s->fetchAll();
    sendJson(['success'=>true,
              'data'=>array_map(fn($r)=>"{$r['medication_name']} ({$r['schedule']})",$rows)]);
}