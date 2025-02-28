;; ChainClinic - Decentralized Medical Records Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-record (err u101))
(define-constant err-already-exists (err u102))

;; Data Variables
(define-map doctors principal bool)
(define-map patient-records 
  { patient: principal }
  { records: (list 200 { hash: (string-ascii 64), doctor: principal, timestamp: uint, data: (string-ascii 1024) }) })
(define-map access-grants { patient: principal, doctor: principal } bool)
(define-map audit-trail 
  { record-hash: (string-ascii 64) }
  { accessed-by: (list 200 { who: principal, when: uint }) })

;; Authorization Functions
(define-private (is-doctor (account principal))
  (default-to false (map-get? doctors account)))

(define-private (has-access (patient principal) (doctor principal))
  (default-to false (map-get? access-grants { patient: patient, doctor: doctor })))

;; Public Functions
(define-public (register-doctor (doctor principal))
  (if (is-eq tx-sender contract-owner)
      (begin
        (map-set doctors doctor true)
        (ok true))
      err-unauthorized))

(define-public (add-record (hash (string-ascii 64)) (patient principal) (data (string-ascii 1024)))
  (let ((doctor tx-sender))
    (if (and (is-doctor doctor) (has-access patient doctor))
        (let ((current-records (default-to { records: (list) } (map-get? patient-records { patient: patient }))))
          (map-set patient-records
            { patient: patient }
            { records: (unwrap-panic (as-max-len? 
              (append (get records current-records)
                { hash: hash, 
                  doctor: doctor,
                  timestamp: block-height,
                  data: data })
              u200)) })
          (ok true))
        err-unauthorized)))

(define-public (grant-access (doctor principal))
  (begin
    (map-set access-grants
      { patient: tx-sender, doctor: doctor }
      true)
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
        (ok (default-to { records: (list) } 
              (map-get? patient-records { patient: patient })))
        err-unauthorized)))
