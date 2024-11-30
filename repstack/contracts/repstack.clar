;; RepStack - DAO Reputation System
;; A reputation tracking system for DAOs on Stacks blockchain

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

;; Data Maps
(define-map user-scores 
    principal 
    {
        reputation-score: uint,
        proposal-count: uint,
        vote-count: uint,
        last-action: uint,
        contribution-count: uint
    }
)

(define-map contribution-weights
    {action: (string-ascii 24)}
    {weight: uint}
)

;; Initialize contribution weights
(map-set contribution-weights {action: "proposal"} {weight: u10})
(map-set contribution-weights {action: "vote"} {weight: u5})
(map-set contribution-weights {action: "contribution"} {weight: u15})

;; Public functions

(define-public (initialize-user)
    (begin
        (asserts! (is-none (get-user-score tx-sender)) (err u103))
        (ok (map-set user-scores tx-sender {
            reputation-score: u0,
            proposal-count: u0,
            vote-count: u0,
            last-action: block-height,
            contribution-count: u0
        }))
    )
)

(define-public (record-proposal)
    (let (
        (user-data (unwrap! (get-user-score tx-sender) (err u104)))
        (proposal-weight (get weight (unwrap! (map-get? contribution-weights {action: "proposal"}) (err u105))))
    )
    (ok (map-set user-scores tx-sender (merge user-data {
        reputation-score: (+ (get reputation-score user-data) proposal-weight),
        proposal-count: (+ (get proposal-count user-data) u1),
        last-action: block-height
    })))
    )
)

(define-public (record-vote)
    (let (
        (user-data (unwrap! (get-user-score tx-sender) (err u104)))
        (vote-weight (get weight (unwrap! (map-get? contribution-weights {action: "vote"}) (err u105))))
    )
    (ok (map-set user-scores tx-sender (merge user-data {
        reputation-score: (+ (get reputation-score user-data) vote-weight),
        vote-count: (+ (get vote-count user-data) u1),
        last-action: block-height
    })))
    )
)

(define-public (record-contribution)
    (let (
        (user-data (unwrap! (get-user-score tx-sender) (err u104)))
        (contribution-weight (get weight (unwrap! (map-get? contribution-weights {action: "contribution"}) (err u105))))
    )
    (ok (map-set user-scores tx-sender (merge user-data {
        reputation-score: (+ (get reputation-score user-data) contribution-weight),
        contribution-count: (+ (get contribution-count user-data) u1),
        last-action: block-height
    })))
    )
)

;; Admin functions

(define-public (update-weight (action (string-ascii 24)) (new-weight uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set contribution-weights {action: action} {weight: new-weight}))
    )
)

;; Read-only functions

(define-read-only (get-user-score (user principal))
    (map-get? user-scores user)
)

(define-read-only (get-action-weight (action (string-ascii 24)))
    (map-get? contribution-weights {action: action})
)

;; Helper functions

(define-private (decay-score (original-score uint) (blocks-passed uint))
    (let (
        (decay-factor (/ blocks-passed u1000))
    )
    (if (> decay-factor u0)
        (/ original-score decay-factor)
        original-score
    ))
)

;; Score calculation with decay
(define-read-only (get-current-score (user principal))
    (let (
        (user-data (unwrap! (get-user-score user) err-not-found))
        (blocks-since-last-action (- block-height (get last-action user-data)))
    )
    (ok (decay-score (get reputation-score user-data) blocks-since-last-action))
    )
)