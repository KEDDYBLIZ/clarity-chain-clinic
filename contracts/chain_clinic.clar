;; ChainClinic - Decentralized Medical Records Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-record (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-hash (err u103))
(define-constant err-expired (err u104))

;; Data Variables
(define-map doctors principal bool)
(define-map patient-records 
  { patient: principal }
  { records: (list 200 { 
    hash: (string-ascii 64), 
    doctor: principal, 
    timestamp: uint,
    category: (string-ascii 20),
    expiration: uint,
    version: uint,
    data: (string-ascii 1024) 
  }) })

(define-map access-grants 
  { patient: principal, doctor: principal } 
  { granted-at: uint, expires: uint, emergency-access: bool })

(define-map audit-trail 
  { record-hash: (string-ascii 64) }
  { accessed-by: (list 200 { 
    who: principal, 
    when: uint,
    action: (string-ascii 20) 
  }) })

;; Private Functions
(define-private (is-doctor (account principal))
  (default-to false (map-get? doctors account)))

(define-private (has-access (patient principal) (doctor principal))
  (match (map-get? access-grants { patient: patient, doctor: doctor })
    grant (and 
           (< block-height (get expires grant))
           (or (get emergency-access grant) true))
    false))

(define-private (validate-hash (hash (string-ascii 64)))
  (> (len hash) u0))

(define-private (log-access (hash (string-ascii 64)) (action (string-ascii 20)))
  (let ((current-audit (default-to { accessed-by: (list) } 
                       (map-get? audit-trail { record-hash: hash }))))
    (map-set audit-trail
      { record-hash: hash }
      { accessed-by: (unwrap-panic (as-max-len? 
        (append (get accessed-by current-audit)
          { who: tx-sender, 
            when: block-height,
            action: action })
        u200)) })))

;; Public Functions
(define-public (register-doctor (doctor principal))
  (if (is-eq tx-sender contract-owner)
      (begin
        (map-set doctors doctor true)
        (ok true))
      err-unauthorized))

(define-public (add-record 
  (hash (string-ascii 64)) 
  (patient principal) 
  (category (string-ascii 20))
  (expiration uint)
  (data (string-ascii 1024)))
  (let ((doctor tx-sender))
    (if (and 
         (is-doctor doctor) 
         (has-access patient doctor)
         (validate-hash hash))
        (let ((current-records (default-to { records: (list) } 
                              (map-get? patient-records { patient: patient }))))
          (map-set patient-records
            { patient: patient }
            { records: (unwrap-panic (as-max-len? 
              (append (get records current-records)
                { hash: hash, 
                  doctor: doctor,
                  timestamp: block-height,
                  category: category,
                  expiration: expiration,
                  version: u1,
                  data: data })
              u200)) })
          (log-access hash "add")
          (ok true))
        err-unauthorized)))

(define-public (grant-access (doctor principal) (duration uint) (emergency bool))
  (begin
    (map-set access-grants
      { patient: tx-sender, doctor: doctor }
      { granted-at: block-height,
        expires: (+ block-height duration),
        emergency-access: emergency })
    (ok true)))

(define-public (revoke-access (doctor principal))
  (begin
    (map-delete access-grants 
      { patient: tx-sender, doctor: doctor })
    (ok true)))

(define-read-only (get-records (patient principal))
  (let ((requester tx-sender))
    (if (or (is-eq patient requester)
            (and (is-doctor requester) 
                 (has-access patient requester)))
        (begin
          (log-access "all" "view")
          (ok (default-to { records: (list) } 
                (map-get? patient-records { patient: patient }))))
        err-unauthorized)))

(define-read-only (get-audit-trail (hash (string-ascii 64)))
  (ok (default-to { accessed-by: (list) }
        (map-get? audit-trail { record-hash: hash }))))
