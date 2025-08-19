;; Instructor Certification System Contract
;; Handles instructor registration, certification tracking, and performance management

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-INSTRUCTOR-NOT-FOUND (err u201))
(define-constant ERR-INSTRUCTOR-ALREADY-EXISTS (err u202))
(define-constant ERR-CERTIFICATION-EXPIRED (err u203))
(define-constant ERR-INVALID-RATING (err u204))
(define-constant ERR-INVALID-INPUT (err u205))
(define-constant ERR-CERTIFICATION-NOT-FOUND (err u206))
(define-constant ERR-INSUFFICIENT-EXPERIENCE (err u207))

;; Data Variables
(define-data-var next-instructor-id uint u1)
(define-data-var min-certification-period uint u30) ;; Minimum 30 days
(define-data-var max-certification-period uint u1095) ;; Maximum 3 years

;; Data Maps
(define-map instructors
  { instructor-principal: principal }
  {
    instructor-id: uint,
    name: (string-ascii 100),
    bio: (string-ascii 500),
    specializations: (list 10 (string-ascii 50)),
    experience-years: uint,
    total-programs-taught: uint,
    average-rating: uint, ;; Out of 100
    total-ratings: uint,
    is-active: bool,
    registered-at: uint,
    last-updated: uint
  }
)

(define-map certifications
  { instructor-principal: principal, cert-type: (string-ascii 50) }
  {
    issuer: principal,
    issued-at: uint,
    expires-at: uint,
    verification-hash: (buff 32),
    is-verified: bool,
    verification-notes: (string-ascii 200)
  }
)

(define-map instructor-ratings
  { instructor-principal: principal, rater: principal, program-id: uint }
  {
    rating: uint, ;; 1-100
    feedback: (string-ascii 300),
    rated-at: uint
  }
)

(define-map certification-authorities
  { authority: principal }
  {
    name: (string-ascii 100),
    authorized-cert-types: (list 20 (string-ascii 50)),
    is-active: bool,
    added-at: uint
  }
)

(define-map instructor-availability
  { instructor-principal: principal }
  {
    available-days: (list 7 bool), ;; Mon-Sun availability
    preferred-program-types: (list 10 (string-ascii 50)),
    max-daily-programs: uint,
    hourly-rate: uint,
    travel-radius: uint ;; in miles
  }
)

;; Read-only functions
(define-read-only (get-instructor-info (instructor-principal principal))
  (map-get? instructors { instructor-principal: instructor-principal })
)

(define-read-only (get-certification (instructor-principal principal) (cert-type (string-ascii 50)))
  (map-get? certifications { instructor-principal: instructor-principal, cert-type: cert-type })
)

(define-read-only (get-instructor-availability (instructor-principal principal))
  (map-get? instructor-availability { instructor-principal: instructor-principal })
)

(define-read-only (is-instructor-certified (instructor-principal principal) (cert-type (string-ascii 50)))
  (match (get-certification instructor-principal cert-type)
    cert-data (and
      (get is-verified cert-data)
      (> (get expires-at cert-data) block-height)
    )
    false
  )
)

(define-read-only (is-instructor-active (instructor-principal principal))
  (match (get-instructor-info instructor-principal)
    instructor-data (get is-active instructor-data)
    false
  )
)

(define-read-only (get-instructor-rating (instructor-principal principal))
  (match (get-instructor-info instructor-principal)
    instructor-data (get average-rating instructor-data)
    u0
  )
)

(define-read-only (is-certification-authority (authority principal))
  (match (map-get? certification-authorities { authority: authority })
    auth-data (get is-active auth-data)
    false
  )
)

(define-read-only (can-issue-certification (authority principal) (cert-type (string-ascii 50)))
  (match (map-get? certification-authorities { authority: authority })
    auth-data (and
      (get is-active auth-data)
      (is-some (index-of (get authorized-cert-types auth-data) cert-type))
    )
    false
  )
)

;; Private functions
(define-private (calculate-new-average-rating (current-avg uint) (current-count uint) (new-rating uint))
  (if (is-eq current-count u0)
    new-rating
    (/ (+ (* current-avg current-count) new-rating) (+ current-count u1))
  )
)

(define-private (is-valid-rating (rating uint))
  (and (>= rating u1) (<= rating u100))
)

;; Public functions
(define-public (register-instructor
  (name (string-ascii 100))
  (bio (string-ascii 500))
  (specializations (list 10 (string-ascii 50)))
  (experience-years uint)
)
  (let ((instructor-id (var-get next-instructor-id)))
    (asserts! (is-none (get-instructor-info tx-sender)) ERR-INSTRUCTOR-ALREADY-EXISTS)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len specializations) u0) ERR-INVALID-INPUT)

    ;; Register the instructor
    (map-set instructors
      { instructor-principal: tx-sender }
      {
        instructor-id: instructor-id,
        name: name,
        bio: bio,
        specializations: specializations,
        experience-years: experience-years,
        total-programs-taught: u0,
        average-rating: u0,
        total-ratings: u0,
        is-active: true,
        registered-at: block-height,
        last-updated: block-height
      }
    )

    ;; Initialize availability (default to all days available)
    (map-set instructor-availability
      { instructor-principal: tx-sender }
      {
        available-days: (list true true true true true true true),
        preferred-program-types: specializations,
        max-daily-programs: u3,
        hourly-rate: u50000, ;; Default 0.05 STX per hour
        travel-radius: u25 ;; Default 25 miles
      }
    )

    (var-set next-instructor-id (+ instructor-id u1))
    (ok instructor-id)
  )
)

(define-public (update-instructor-profile
  (name (string-ascii 100))
  (bio (string-ascii 500))
  (specializations (list 10 (string-ascii 50)))
  (experience-years uint)
)
  (let ((instructor-data (unwrap! (get-instructor-info tx-sender) ERR-INSTRUCTOR-NOT-FOUND)))
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len specializations) u0) ERR-INVALID-INPUT)

    (map-set instructors
      { instructor-principal: tx-sender }
      (merge instructor-data {
        name: name,
        bio: bio,
        specializations: specializations,
        experience-years: experience-years,
        last-updated: block-height
      })
    )

    (ok true)
  )
)

(define-public (update-availability
  (available-days (list 7 bool))
  (preferred-program-types (list 10 (string-ascii 50)))
  (max-daily-programs uint)
  (hourly-rate uint)
  (travel-radius uint)
)
  (begin
    (asserts! (is-some (get-instructor-info tx-sender)) ERR-INSTRUCTOR-NOT-FOUND)
    (asserts! (> max-daily-programs u0) ERR-INVALID-INPUT)
    (asserts! (> hourly-rate u0) ERR-INVALID-INPUT)

    (map-set instructor-availability
      { instructor-principal: tx-sender }
      {
        available-days: available-days,
        preferred-program-types: preferred-program-types,
        max-daily-programs: max-daily-programs,
        hourly-rate: hourly-rate,
        travel-radius: travel-radius
      }
    )

    (ok true)
  )
)

(define-public (issue-certification
  (instructor-principal principal)
  (cert-type (string-ascii 50))
  (validity-days uint)
  (verification-hash (buff 32))
  (verification-notes (string-ascii 200))
)
  (begin
    (asserts! (is-certification-authority tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (can-issue-certification tx-sender cert-type) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (get-instructor-info instructor-principal)) ERR-INSTRUCTOR-NOT-FOUND)
    (asserts! (>= validity-days (var-get min-certification-period)) ERR-INVALID-INPUT)
    (asserts! (<= validity-days (var-get max-certification-period)) ERR-INVALID-INPUT)

    (map-set certifications
      { instructor-principal: instructor-principal, cert-type: cert-type }
      {
        issuer: tx-sender,
        issued-at: block-height,
        expires-at: (+ block-height validity-days),
        verification-hash: verification-hash,
        is-verified: true,
        verification-notes: verification-notes
      }
    )

    (ok true)
  )
)

(define-public (revoke-certification (instructor-principal principal) (cert-type (string-ascii 50)))
  (let ((cert-data (unwrap! (get-certification instructor-principal cert-type) ERR-CERTIFICATION-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get issuer cert-data)) ERR-NOT-AUTHORIZED)

    (map-set certifications
      { instructor-principal: instructor-principal, cert-type: cert-type }
      (merge cert-data { is-verified: false })
    )

    (ok true)
  )
)

(define-public (rate-instructor
  (instructor-principal principal)
  (program-id uint)
  (rating uint)
  (feedback (string-ascii 300))
)
  (let (
    (instructor-data (unwrap! (get-instructor-info instructor-principal) ERR-INSTRUCTOR-NOT-FOUND))
    (current-avg (get average-rating instructor-data))
    (current-count (get total-ratings instructor-data))
    (new-avg (calculate-new-average-rating current-avg current-count rating))
  )
    (asserts! (is-valid-rating rating) ERR-INVALID-RATING)
    ;; Note: In a full implementation, we'd verify the rater participated in the program

    ;; Record the rating
    (map-set instructor-ratings
      { instructor-principal: instructor-principal, rater: tx-sender, program-id: program-id }
      {
        rating: rating,
        feedback: feedback,
        rated-at: block-height
      }
    )

    ;; Update instructor's average rating
    (map-set instructors
      { instructor-principal: instructor-principal }
      (merge instructor-data {
        average-rating: new-avg,
        total-ratings: (+ current-count u1),
        last-updated: block-height
      })
    )

    (ok new-avg)
  )
)

(define-public (increment-programs-taught (instructor-principal principal))
  (let ((instructor-data (unwrap! (get-instructor-info instructor-principal) ERR-INSTRUCTOR-NOT-FOUND)))
    ;; Only allow calls from program-scheduling contract
    (asserts! (is-eq tx-sender .program-scheduling) ERR-NOT-AUTHORIZED)

    (map-set instructors
      { instructor-principal: instructor-principal }
      (merge instructor-data {
        total-programs-taught: (+ (get total-programs-taught instructor-data) u1),
        last-updated: block-height
      })
    )

    (ok true)
  )
)

(define-public (deactivate-instructor)
  (let ((instructor-data (unwrap! (get-instructor-info tx-sender) ERR-INSTRUCTOR-NOT-FOUND)))
    (map-set instructors
      { instructor-principal: tx-sender }
      (merge instructor-data { is-active: false })
    )

    (ok true)
  )
)

(define-public (reactivate-instructor)
  (let ((instructor-data (unwrap! (get-instructor-info tx-sender) ERR-INSTRUCTOR-NOT-FOUND)))
    (map-set instructors
      { instructor-principal: tx-sender }
      (merge instructor-data { is-active: true })
    )

    (ok true)
  )
)

;; Admin functions (only contract owner)
(define-public (add-certification-authority
  (authority principal)
  (name (string-ascii 100))
  (authorized-cert-types (list 20 (string-ascii 50)))
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len authorized-cert-types) u0) ERR-INVALID-INPUT)

    (map-set certification-authorities
      { authority: authority }
      {
        name: name,
        authorized-cert-types: authorized-cert-types,
        is-active: true,
        added-at: block-height
      }
    )

    (ok true)
  )
)

(define-public (remove-certification-authority (authority principal))
  (let ((auth-data (unwrap! (map-get? certification-authorities { authority: authority }) ERR-NOT-AUTHORIZED)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (map-set certification-authorities
      { authority: authority }
      (merge auth-data { is-active: false })
    )

    (ok true)
  )
)

(define-public (set-certification-periods (min-days uint) (max-days uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (< min-days max-days) ERR-INVALID-INPUT)
    (asserts! (>= min-days u1) ERR-INVALID-INPUT)

    (var-set min-certification-period min-days)
    (var-set max-certification-period max-days)

    (ok true)
  )
)

(define-public (emergency-deactivate-instructor (instructor-principal principal))
  (let ((instructor-data (unwrap! (get-instructor-info instructor-principal) ERR-INSTRUCTOR-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (map-set instructors
      { instructor-principal: instructor-principal }
      (merge instructor-data { is-active: false })
    )

    (ok true)
  )
)
